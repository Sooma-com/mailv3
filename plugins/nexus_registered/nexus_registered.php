<?php
declare(strict_types=1);
use Nexus\Payload\CustomerAction;
require_once(__DIR__ . "/vendor/autoload.php");
/**
 * Nexus mail account upgrade plugin for Roundcube
 *
 * @author Sérgio Carvalho <daf@sooma.com>
 *
 * Copyright (C) Sooma.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */
class nexus_registered extends rcube_plugin
{
    public $rc;
    public $client = null;
    public $config = null;
    public $_db = null;

    public function init()
    {
        if (!isset($_SESSION['username'])) return;
        $config_domain = explode('@', $_SESSION['username']);
        if (count($config_domain) !== 2) return;
        $config_domain = $config_domain[1];
        $this->rc = rcmail::get_instance();
        $GLOBALS['debug'] = true;
        $this->load_config();
        $infinite_recursion_guard = 1000;
        while (is_null($this->config) && $infinite_recursion_guard > 0 && isset($this->rc->config->get('nexus_registered')[$config_domain])) {
            if (is_string($this->rc->config->get('nexus_registered')[$config_domain])) {
                $config_domain = $this->rc->config->get('nexus_registered')[$config_domain];
            } else {
                $this->config = $this->rc->config->get('nexus_registered')[$config_domain];
            }
            $infinite_recursion_guard--;
        }
        if (is_null($this->config)) return;
        $this->config = $this->rc->config->get('nexus_registered')[$config_domain];
        $this->add_texts('localization/');
        $this->include_script('js/nexus_registered.js');
        $this->add_hook('render_page', [$this, 'add_labels']);
        $this->add_hook('message_before_send', [$this, 'mark_message_as_registered']);
        $this->register_action('plugin.nexus_registered_setting', [$this, 'nexus_registered_setting']);
        $this->rc->output->add_handlers([
            'compose-registered' => [$this, 'compose_checkbox'],
        ]);
        if ($this->rc->task == 'settings') {
            $this->add_hook('settings_actions', [$this, 'settings_actions']);
        }
    }
    public function db() {
        if ($this->_db === null) {
            $db_config = $this->config['sooma_db'];
            $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', 
                $db_config['host'], 
                $db_config['port'], 
                $db_config['dbname']
            );
            $db = new PDO($dsn, $db_config['username'], $db_config['password']);
            $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->_db = $db;
        }
        return $this->_db;
    }
    public function db_exec($query, $params) {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue($key, $value);
        $stmt->execute();
    }

    public function db_query_row($query, $params) {
        $stmt = $this->db()->prepare($query);
        foreach ($params as $key => $value) $stmt->bindValue($key, $value);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        return $result;
    }

    public function add_labels(?array $args): void
    {
        // $this->rc->output->add_label('nexus_registered.upgrade');
    }
    public function start(?string $mode = null): int {
        return 0;
    }
    public function compose_checkbox(array $attrib): string {
        $registered_label = $this->rc->gettext('registered_checkbox', 'nexus_registered');
        // Split off the label's last word so it can be wrapped together
        // with the .help-tip icon in .help-tip-nowrap below - see that
        // widget's comment (widgets/_help-tip.scss) for why a trailing
        // &nbsp; alone doesn't reliably keep them on the same line
        // (Manuel, 2026-07-04). Falls back to the whole label as the
        // "last word" if it's a single word, which still works fine with
        // the same markup.
        $registered_label_words = explode(' ', $registered_label);
        $registered_label_last_word = array_pop($registered_label_words);
        $registered_label_rest = implode(' ', $registered_label_words);
        ob_start();
        ?>
<!--
    Added a .help-tip (skin's shared widget, widgets/_help-tip.scss) next
    to the label - "Email registado" alone doesn't explain what the
    feature actually does (a certified, timestamped send/receipt record,
    per this plugin's own registration-stamp accounting), and it's the
    very first control a lawyer using this sees in the compose sidebar
    (Manuel, 2026-07-04).
-->
<div class="form-group row form-check" id="compose-registered-row">
	<label for="compose-registered" class="col-form-label col-6"><?= $registered_label_rest ? htmlspecialchars($registered_label_rest) . ' ' : '' ?><span class="help-tip-nowrap"><?= htmlspecialchars($registered_label_last_word) ?> <span class="help-tip" tabindex="0">
			<span class="help-tip-icon" aria-hidden="true">?</span>
			<span class="help-tip-bubble" role="tooltip">Envia esta mensagem como registada, com prova certificada da data e hora de envio e de receção pelo servidor do destinatário.</span>
		</span></span>
	</label>
    <div class="col-6 form-check">
        <input name="_registered" id="compose-registered" tabindex="2" class="form-check-input" value="1" type="checkbox">
    </div>
</div>
        <?php
        return ob_get_clean();
    }
    public function mark_message_as_registered(array $args): array {
        $headers = [
            'X-Sooma-Timestamp' => empty($_POST['_registered']) ? "No" : "Yes"
        ];
        $args['message']->headers($headers, true);
        return $args;
    }
    public function settings_actions(array $args): array {
        $args['actions'][] = [
            'action' => 'plugin.nexus_registered_setting',
            'class'  => 'status',
            'label'  => 'settings_label',
            'domain' => 'nexus_registered',
            'title'  => 'settings_title',
        ];
        return $args;
    }
    public function nexus_registered_setting(): void {
        if ($_SERVER['REQUEST_METHOD'] == 'GET') {
            $this->nexus_registered_setting_get();
        } else if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            $this->nexus_registered_setting_post();
        }
    }
    public function nexus_registered_setting_get(): void {
        $this->register_handler('plugin.body', [$this, 'nexus_registered_settings_body']);

        $this->rc->output->set_pagetitle($this->gettext('settings_title'));
        $this->include_script('js/upgrade.js');

        $this->rc->output->send('plugin');
    }
    public function nexus_registered_setting_post(): void {
        $default_active = rcube_utils::get_input_value('default_active', rcube_utils::INPUT_POST);
        if (is_null($default_active)) {
            $this->nexus_registered_setting_post_upgrade();
        } else {
            $this->nexus_registered_setting_post_default_active();
        }
    }
    public function nexus_registered_setting_post_upgrade(): void {
        $customer_name = rcube_utils::get_input_value('customer_name', rcube_utils::INPUT_POST);
        $customer_vat_id = rcube_utils::get_input_value('customer_vat_id', rcube_utils::INPUT_POST);
        $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
        $nexus_customer = $nexus_client->get_customers(['email' => $_SESSION['username']]);
        if (count($nexus_customer) > 0) {
            $nexus_customer = $nexus_customer[0];
        } else {
            $nexus_address = new Nexus\Address();
            $nexus_address->country = 'PT';
            $customer = new Nexus\Customer();
            $customer->name = $customer_name;
            $customer->email = $_SESSION['username'];
            $customer->tax_id = $customer_vat_id;
            $customer->currency = 'EUR';
            $nexus_customer = $nexus_client->post_customer(json_encode([
                'customer' => $customer->to_dict(),
                'address' => $nexus_address->to_dict(),
            ], JSON_FORCE_OBJECT));
        }
        $current_subscription = $this->get_current_subscription();
        if ($current_subscription) {
            $product_id = rcube_utils::get_input_value('product', rcube_utils::INPUT_POST);
            if ($product_id == "") {
                // Customer has a subscription and requested a cancellation. Cancel the subscription.
                $result = $nexus_client->cancel_subscription($current_subscription->id);
                if (!$result->customer_action) {
                    $result->customer_action = new Nexus\Payload\CustomerAction();
                    $result->customer_action->type = Nexus\Payload\CustomerAction::TYPE_NONE;
                }
                $customer_action = $result->customer_action;
            } else {
                $price_period = rcube_utils::get_input_value('price', rcube_utils::INPUT_POST);
                $price = $nexus_client->get_prices();
                $price = array_filter($price, function ($price) use ($product_id, $price_period) {
                    return $price->active && $price->product == $product_id && 
                    $price->recurring_interval['microseconds'] == 0 && $price->recurring_interval['days'] == 0 &&
                    ($price_period == 'yearly' && $price->recurring_interval['months'] == 12 
                    || ($price_period == 'monthly' && $price->recurring_interval['months'] == 1));
                });
                $price = array_pop($price);
                if (!$price) throw new Exception('Price not found');
                if ($current_subscription->price == $price->id) {
                    // Customer has a subscription and requested an early renewal. Renew the subscription.
                    $extension = new Nexus\Payload\SubscriptionExtension();
                    $payment_method = rcube_utils::get_input_value('payment_method', rcube_utils::INPUT_POST);
                    if ($payment_method == 'credit_card') {
                        $extension->payment_plugin = 'stripe';
                    } else if ($payment_method == 'mb') {
                        $extension->payment_plugin = 'easypay';
                    } else if ($payment_method == 'mbway') {
                        $extension->payment_plugin = 'easypay';
                        $mbway_telephone = rcube_utils::get_input_value('mbway_telephone', rcube_utils::INPUT_POST);
                        $extension->metadata = [ 'easypay' => [ 'mbway' => [ 'telephone' => $mbway_telephone ] ] ];
                    } else {
                        throw new Exception('Invalid payment method');
                    }
                    $extension->language = 'pt';
                    $extension->invoicing_plugin = 'internal';
                    $result = $nexus_client->extend_subscription($current_subscription->id, $extension);
                    $customer_action = $result->customer_action;
                } else {
                    $payload = new Nexus\Payload\SubscriptionPayload();
                    $payload->subscription = new Nexus\Subscription();
                    $payload->subscription->id = $current_subscription->id;
                    $payload->subscription->price = $price->id;
                    $payload->subscription->currency = 'EUR';
                    $payment_method = rcube_utils::get_input_value('payment_method', rcube_utils::INPUT_POST);
                    if ($payment_method == 'credit_card') {
                        $payload->payment_plugin = 'stripe';
                    } else if ($payment_method == 'mb') {
                        $payload->payment_plugin = 'easypay';
                    } else if ($payment_method == 'mbway') {
                        $payload->payment_plugin = 'easypay';
                        $mbway_telephone = rcube_utils::get_input_value('mbway_telephone', rcube_utils::INPUT_POST);
                        $payload->metadata = [ 'easypay' => [ 'mbway' => [ 'telephone' => $mbway_telephone ] ] ];
                    } else {
                        throw new Exception('Invalid payment method');
                    }
                    $payload->language = 'pt';
                    $payload->invoicing_plugin = 'internal';
                    // Customer has a subscription and requested a price change (upgrade, downgrade, period change)
                    $result = $nexus_client->put_subscription($payload);
                    $customer_action = $result->customer_action;
                }
            }
        } else {
            $product_id = rcube_utils::get_input_value('product', rcube_utils::INPUT_POST);
            if ($product_id == "") {
                // Customer has no subscription and requested a cancellation. 
                $customer_action = new Nexus\Payload\CustomerAction();
                $customer_action->type = Nexus\Payload\CustomerAction::TYPE_NONE;
            } else {
                // Customer has no subscription and requested a new subscription. Create a new subscription.
                $price_period = rcube_utils::get_input_value('price', rcube_utils::INPUT_POST);
                $price = $nexus_client->get_prices();
                $price = array_filter($price, function ($price) use ($product_id, $price_period) {
                    return $price->active && $price->product == $product_id && 
                    $price->recurring_interval['microseconds'] == 0 && $price->recurring_interval['days'] == 0 &&
                    ($price_period == 'yearly' && $price->recurring_interval['months'] == 12 
                    || ($price_period == 'monthly' && $price->recurring_interval['months'] == 1));
                });
                $price = array_pop($price);
                if (!$price) throw new Exception('Price not found');
                $new_subscription = new Nexus\Payload\SubscriptionPayload();
                $new_subscription->subscription = new Nexus\Subscription();
                $new_subscription->subscription->customer = $nexus_customer->id;
                $new_subscription->subscription->price = $price->id;
                $new_subscription->subscription->currency = 'EUR';
                $payment_method = rcube_utils::get_input_value('payment_method', rcube_utils::INPUT_POST);
                if ($payment_method == 'credit_card') {
                    $new_subscription->payment_plugin = 'stripe';
                } else if ($payment_method == 'mb') {
                    $new_subscription->payment_plugin = 'easypay';
                } else if ($payment_method == 'mbway') {
                    $new_subscription->payment_plugin = 'easypay';
                    $mbway_telephone = rcube_utils::get_input_value('mbway_telephone', rcube_utils::INPUT_POST);
                    $new_subscription->subscription->metadata = [ 'easypay' => [ 'mbway' => [ 'telephone' => $mbway_telephone ] ] ];
                } else {
                    throw new Exception('Invalid payment method');
                }
                $new_subscription->language = 'pt';
                $new_subscription->invoicing_plugin = 'internal';
                $result = $nexus_client->post_subscription($new_subscription);
                $customer_action = $result->customer_action;
            }
        }
        if ($customer_action->type == CustomerAction::TYPE_REDIRECT) {
            header('Location: ' . $customer_action->url);
            exit;
        }
        $this->start();
        $this->rc->output->set_pagetitle($this->rc->gettext('pagetitle.upgrade', 'nexus_storage'));
        $this->rc->output->set_env('customer_action', $customer_action->to_dict());
        if ($customer_action->type == CustomerAction::TYPE_MULTIBANCO) {
            $this->rc->output->send('nexus_registered.multibanco');
        } else if ($customer_action->type == CustomerAction::TYPE_MBWAY) {
            $this->rc->output->send('nexus_registered.mbway');
        } else if ($customer_action->type == CustomerAction::TYPE_NONE) {
            $this->rc->output->send('nexus_registered.no_payment_instructions');
        } else {
            throw new Exception('Invalid customer action type');
        }
    }
    public function nexus_registered_setting_post_default_active(): void {
        $default_active = rcube_utils::get_input_value('default_active', rcube_utils::INPUT_POST) == "1" ? "t" : "f";
        $exists = $this->db_query_row("SELECT email FROM registado.stock WHERE email = LOWER(:email)", ['email' => $_SESSION['username']]);
        if ($exists) {
            $this->db_exec("UPDATE registado.stock SET default_active = :default_active WHERE email = LOWER(:email)", ['default_active' => $default_active, 'email' => $_SESSION['username']]);
        } else {
            $this->db_exec("INSERT INTO registado.stock (email, default_active, available_timestamps) VALUES (LOWER(:email), :default_active, 0)", ['email' => $_SESSION['username'], 'default_active' => $default_active]);
        }
        $this->rc->output->redirect(['task' => 'settings', 'action' => 'plugin.nexus_registered_setting'], 0, true);
    }
    public function nexus_registered_settings_body(): string {
        ob_start();
        $default_active = $this->db_query_row("SELECT available_timestamps, default_active FROM registado.stock WHERE email = LOWER(:email)", ['email' => $_SESSION['username']]);
        $available_timestamps = is_array($default_active) ? $default_active['available_timestamps'] : 0;
        $default_active = is_array($default_active) ? $default_active['default_active'] : false;
?>
<div id="prefs-title" class="boxtitle"><?= $this->gettext('settings_settings_section_title', 'nexus_registered') ?></div>
<div class="box formcontainer scroller">
 <form action="<?= $this->rc->url(['task' => 'settings', 'action' => 'plugin.nexus_registered_setting'], true) ?>" method="post">
  <table class="propform">
   <tbody>
    <tr>
      <td class="title" width="10" style="text-wrap: nowrap;"><label for="always_enabled"><?= $this->gettext('register_all_emails', 'nexus_registered') ?></label></td>
      <td><select name="default_active" id="default_active">
          <option value="1" <?= $default_active ? 'selected' : '' ?>><?= $this->gettext('yes', 'nexus_registered') ?></option>
          <option value="0" <?= !$default_active ? 'selected' : '' ?>><?= $this->gettext('no_default_active', 'nexus_registered') ?></option>
      </select>
      </td>
    </tr>
  </tbody></table>
  <p class="formbuttons footerleft"><button class="button mainaction submit" type="submit" value="save"><?= $this->gettext('save', 'nexus_registered') ?></button></p>
 </form>
</div>
<div class="box formcontainer scroller">
 <table class="propform">
  <tbody>
   <tr>
     <td class="title" width="10" style="text-wrap: nowrap;"><label for="available_timestamps"><?= $this->gettext('available_timestamps', 'nexus_registered') ?></label></td>
     <td><?= $available_timestamps ?></td>
   </tr>
 </tbody></table>
</div>
<div id="prefs-title" class="boxtitle" style="margin-top: 1rem; margin-bottom: 1rem;"><?= $this->gettext('settings_subscription_section_title', 'nexus_registered') ?></div>
<?php 
if ($this->has_subscription_pending_payment()) {
?>
<div class="box formcontainer scroller">
 <p class="form-instructions"><?= $this->gettext('subscription_pending_payment', 'nexus_registered') ?></p>
</div>
<?php
} else {
?>
<form id="upgrade-form" action="<?= $this->rc->url(['task' => 'settings', 'action' => 'plugin.nexus_registered_setting'], true) ?>" method="post" class="nexus">
<?php
        $this->product_selector();
        $this->customer_info();
        $this->payment_method();
?>
</form>
<?php
        }
        return ob_get_clean();
    }
    public function product_selector(): void {
        $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
        $products = array_filter($nexus_client->get_products(), function ($product) {
            return $product->get_metadata('registado');
        });
        $current_subscription = $this->get_current_subscription($products);
        $product_chains = [];
        while (count($products) > 0) {
            $product = array_shift($products);
            if ($up_id = $product->get_metadata('upgrade.up')) {
                $in_chain = array_filter($product_chains, function ($chain) use ($up_id) {
                    return $chain->id == $up_id;
                });
                $in_chain = array_pop($in_chain);
                if ($in_chain) {
                    $product->upgrade_to = $in_chain;
                    $product_chains[] = $product;
                    $product_chains = array_filter($product_chains, function ($chain) use ($product) {
                        return $chain->id != $product->id;
                    });
                } else {
                    $product_chains[] = $product;
                }
            } else if ($down_id = $product->get_metadata('upgrade.down')) {
                $in_chain = array_filter($product_chains, function ($chain) use ($down_id) {
                    return $chain->id == $down_id;
                });
                $in_chain = array_pop($in_chain);
                if ($in_chain) {
                    $in_chain->upgrade_to = $product;
                } else {
                    $product_chains[] = $product;
                }
            } else {
                $product_chains[] = $product;
            }
        }
        $template_products = [];
        foreach ($product_chains as $product) {
            $cursor = $product;
            while ($cursor) {
                $template_products[] = [
                    'nexus_id' => $product->id,
                    'name' => $product->name,
                    'price' => [
                    ]
                ];
                $cursor = $cursor->upgrade_to;
            }
        }
        foreach (array_filter($nexus_client->get_prices(),
            function ($price) {
                return $price->active;
            }
        ) as $price) {
            foreach ($template_products as &$template_product) {
                if ($template_product['nexus_id'] == $price->product) {
                    if ($price->recurring_interval['microseconds'] == 0
                        && $price->recurring_interval['days'] == 0
                        && $price->recurring_interval['months'] == 1
                    ) {
                        $template_product['price']['monthly'] = (float) $price->recurring_rule->__toString();
                    }
                    if ($price->recurring_interval['microseconds'] == 0
                        && $price->recurring_interval['days'] == 0
                        && $price->recurring_interval['months'] == 12
                    ) {
                        $template_product['price']['yearly'] = (float) $price->recurring_rule->__toString();
                    }
                }
            }
        }
        foreach ($template_products as &$template_product) {
            $template_product['action'] = 'upgrade';
            $template_product['current'] = false;
        }
        if ($current_subscription) {
            $price = $nexus_client->get_price($current_subscription->price);
            $found_product = false;
            foreach ($template_products as $index => &$template_product) {
                if (!$found_product) {
                    $template_product['action'] = 'downgrade';
                } else {
                    $template_product['action'] = 'upgrade';
                }
                if ($template_product['nexus_id'] == $price->product) {
                    $found_product = true;
                    $template_product['action'] = 'renew';
                    $template_product['current'] = true;
                    $template_product['ends_at'] = $current_subscription->ends;
                }
            }
        }
?>
<span class="form-instructions"><?= $this->rc->gettext('nexus_storage.select-product', 'nexus_storage'); ?></span>
<fieldset id="nexus-product-selector">
<?php
        foreach ($template_products as &$template_product) {
?>
<label class="nexus-product-option<?= $template_product['current'] ? ' current' : ''; ?>">
 <input type="radio" name="product" value="<?= $template_product['nexus_id']; ?>"<?= count($template_products) == 1 ? ' checked' : ''; ?>>
 <span class="nexus-product-option-name"><?= $template_product['name']; ?></span>
 <span class="nexus-product-option-ends_at"><?= isset($template_product['ends_at']) && $template_product['ends_at'] ? ( $template_product['ends_at'] === true ? $this->rc->gettext('product.ends_at_infinity', 'nexus_storage') : ( $this->rc->gettext('product.ends_at', 'nexus_storage') . date('Y-m-d', strtotime($template_product['ends_at'])) )) : ''; ?></span>
<?php if ($template_product['action'] != 'none') { ?>
 <span class="nexus-product-option-action<?= $template_product['action'] ? sprintf(' action-%s', $template_product['action']) : ' no-action'; ?>"><?php switch ($template_product['action']) {
    case 'upgrade':
        print($this->rc->gettext('action.upgrade', 'nexus_storage'));
        break;
    case 'downgrade':
        print($this->rc->gettext('action.downgrade', 'nexus_storage'));
        break;
    case 'renew':
        print($this->rc->gettext('action.renew', 'nexus_storage'));
        break;
 } ?>
 </span>
<?php } ?>
</label>
<?php
        }
?>
</fieldset>
<fieldset id="nexus-price-selector">
 <span class="form-instructions"><?= $this->rc->gettext('nexus_storage.select-price', 'nexus_storage'); ?></span>
<?php
        foreach ($template_products as &$template_product) if (count($template_product['price']) > 0) { ?>
 <span class="nexus-price-options" data-product="<?= $template_product['nexus_id']; ?>">
<?php       if (isset($template_product['price']['monthly'])) { ?>
  <label class="nexus-price-option monthly">
   <input type="radio" name="price" value="monthly">
   <span class="nexus-price-option-name"><?= $this->rc->gettext('monthly_subscription', 'nexus_storage'); ?></span>
 <?= sprintf('%0.2f', $template_product['price']['monthly']); ?>€ / <?= $this->rc->gettext('month', 'nexus_storage'); ?>
  </label>
<?php        } ?>
<?php       if (isset($template_product['price']['yearly'])) { ?>
  <label class="nexus-price-option yearly">
   <input type="radio" name="price" value="yearly">
   <span class="nexus-price-option-name"><?= $this->rc->gettext('yearly_subscription', 'nexus_storage'); ?></span>
 <?= sprintf('%0.2f', $template_product['price']['yearly'] / 12); ?>€ / <?= $this->rc->gettext('month', 'nexus_storage'); ?>
   <span class="nexus-price-option-yearly-total"><?= $template_product['price']['yearly']; ?>€ / <?= $this->rc->gettext('year', 'nexus_storage'); ?></span>
  </label>
<?php        } ?>
 </span>
 <?php  } ?>
 <span class="form-notes"><?= $this->rc->gettext('nexus_storage.added-vat', 'nexus_storage'); ?></span>
</fieldset>
<?php
    }
    public function customer_info(): void {
        $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
        $nexus_customer = $nexus_client->get_customers(['email' => $_SESSION['username']]);
        if (count($nexus_customer) > 0) {
            $nexus_customer = $nexus_customer[0];
        } else {
            $nexus_customer = null;
        }
        if ($nexus_customer) {
            $customer_name = $nexus_customer->name;
            $customer_vat_id = $nexus_customer->tax_id;
        } else {
            $customer_name = "";
            $customer_vat_id = "";
        }
?>
<fieldset id="nexus-customer-info">
 <span class="form-instructions"><?= $this->rc->gettext('nexus_storage.fill-customer-info', 'nexus_storage'); ?></span>
 <label><?= $this->rc->gettext('customer_vat_id', 'nexus_storage'); ?>
  <input required type="text" name="customer_vat_id" value="<?= $customer_vat_id; ?>" placeholder="PT123123123">
  <span class="form-error"></span>
 </label>
 <label><?= $this->rc->gettext('customer_name', 'nexus_storage'); ?>
  <input required type="text" name="customer_name" value="<?= $customer_name; ?>">
  <span class="form-error"></span>
 </label>
</fieldset>
<?php
    }
    public function has_subscription_pending_payment(?array $products = null): bool {
        if (is_null($products)) {
            $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
            $products = array_filter($nexus_client->get_products(), function ($product) {
                return $product->get_metadata('registado');
            });
        }
        $products = array_reduce(array_map(function ($product) {
            return $product->id;
        }, $products),
            function ($acc, $id) {
                $acc[$id] = true;
                return $acc;
            },
            []
        );
        static $memoized = 'undefined';
        if ($memoized === 'undefined') {
            $memoized = false;
            $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
            $nexus_customer = $nexus_client->get_customers(['email' => $_SESSION['username']]);
            $current_subscription = null;
            if (count($nexus_customer) > 0) {
                $nexus_customer = $nexus_customer[0];
                if ($nexus_customer) {
                    $candidate_subscriptions = array_values(array_filter(
                        $nexus_client->get_subscriptions(['customer' => $nexus_customer->id]),
                        function ($subscription) use ($products) {
                            return isset($products[$subscription->product]) && 
                            (is_null($subscription->ends) || ($subscription->ends && new DateTime($subscription->ends) < new DateTime()));
                        }
                    ));
                    $candidate_subscriptions = array_filter($candidate_subscriptions, function ($subscription) use ($nexus_client) {
                        $invoices = $nexus_client->get_subscription_invoices($subscription->id);
                        foreach ($invoices as $invoice) {
                            if ($invoice->status == 'open' || $invoice->status == 'published') {
                                return true;
                            }
                        }
                        return false;
                    });
                    $memoized = count($candidate_subscriptions) > 0;
                }
            }
        }
        return $memoized;
    }
    public function get_current_subscription(?array $products = null): ?Nexus\Subscription {
        if (is_null($products)) {
            $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
            $products = array_filter($nexus_client->get_products(), function ($product) {
                return $product->get_metadata('registado');
            });
        }
        $products = array_reduce(array_map(function ($product) {
            return $product->id;
        }, $products),
            function ($acc, $id) {
                $acc[$id] = true;
                return $acc;
            },
            []
        );
        static $memoized = 'undefined';
        if ($memoized === 'undefined') {
            $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
            $nexus_customer = $nexus_client->get_customers(['email' => $_SESSION['username']]);
            $current_subscription = null;
            if (count($nexus_customer) > 0) {
                $nexus_customer = $nexus_customer[0];
                if ($nexus_customer) {
                    $current_subscription = array_values(array_filter(
                        $nexus_client->get_subscriptions(['customer' => $nexus_customer->id]),
                        function ($subscription) use ($products) {
                            return isset($products[$subscription->product]) && 
                            $subscription->ends && new DateTime($subscription->ends) > new DateTime();
                        }
                    ));
                    if (count($current_subscription) > 0) {
                        $current_subscription = array_pop($current_subscription);
                    } else {
                        $current_subscription = null;
                    }
                }
            }
            $memoized = $current_subscription;
        }
        return $memoized;
    }
    public function payment_method(): void {
        $current_subscription = $this->get_current_subscription(null);
        $latest_invoice = null;
        if ($current_subscription) {
            $nexus_client = new Nexus\Client($this->config['api_key'], $this->config['endpoint']);
            $latest_invoice = array_values(array_filter(
                $nexus_client->get_subscription_invoices($current_subscription->id),
                function ($invoice) {
                    return $invoice->status == 'paid';
                }
            ));
            if (count($latest_invoice) > 0) {
                $latest_invoice = array_pop($latest_invoice);
            }
        }
        $last_payment_gateway = null;
        if ($latest_invoice) {
            if (array_key_exists('stripe', $latest_invoice->metadata)) {
                $last_payment_gateway = 'stripe';
            }
            if (array_key_exists('easypay', $latest_invoice->metadata)) {
                $last_payment_gateway = 'easypay';
            }
        }
?>
<fieldset id="nexus-payment-method">
 <span class="form-instructions"><?= $this->rc->gettext('nexus_storage.select-payment-method', 'nexus_storage'); ?></span>
 <div class="radio-group">
<?php if (is_null($last_payment_gateway) || $last_payment_gateway == 'stripe') { ?>
  <label class="monthly yearly">
   <input type="radio" name="payment_method" value="credit_card">
   <img height="40" src="/plugins/nexus_storage/img/visa-mastercard.svg" alt="<?= $this->rc->gettext('credit_card', 'nexus_storage'); ?>">
  </label>
<?php } ?>
<?php if (is_null($last_payment_gateway) || $last_payment_gateway == 'easypay') { ?>
  <label class="yearly">
   <input type="radio" name="payment_method" value="mb">
   <img height="40" src="/plugins/nexus_storage/img/mb.svg" alt="<?= $this->rc->gettext('multibanco', 'nexus_storage'); ?>">
  </label>
  <label class="yearly">
   <input type="radio" name="payment_method" value="mbway">
   <img height="40" src="/plugins/nexus_storage/img/mbway.svg" alt="<?= $this->rc->gettext('mbway', 'nexus_storage'); ?>">
  </label>
 </div>
 <label id="mbway-data"><?= $this->rc->gettext('mbway_telephone', 'nexus_storage'); ?>
  <input required type="text" name="mbway_telephone" placeholder="91001002003">
  <button type="submit"><?= $this->rc->gettext('start_payment', 'nexus_storage'); ?></button>
 </label>
<?php } ?>
</fieldset>
<?php
    }
}
