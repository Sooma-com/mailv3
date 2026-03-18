<?php
declare(strict_types=1);
namespace Nexus;
require_once(__DIR__ . "/exception.php");
require_once(__DIR__ . "/apierror.php");
require_once(__DIR__ . "/http.php");
require_once(__DIR__ . "/product.php");
require_once(__DIR__ . "/price.php");
require_once(__DIR__ . "/pricerule.php");
require_once(__DIR__ . "/priceruletoken.php");
require_once(__DIR__ . "/customer.php");
require_once(__DIR__ . "/customer.php");
require_once(__DIR__ . "/address.php");
require_once(__DIR__ . "/subscription.php");
require_once(__DIR__ . "/invoice.php");
require_once(__DIR__ . "/invoice_line.php");
require_once(__DIR__ . "/payload/subscription_payload.php");
require_once(__DIR__ . "/payload/edit_subscription_result.php");
require_once(__DIR__ . "/payload/customer_action.php");
require_once(__DIR__ . "/payload/subscription_extension.php");

class Client
{
    private $api_key;
    private $endpoint;

    public function __construct($api_key, $endpoint)
    {
        $this->api_key = $api_key;
        $this->endpoint = $endpoint;
    }

    public function get_products(): array {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get_paged('settings/product/collection/');
        return array_map(function ($item) { return Product::from_json($item); }, $json['data']);
    }
    public function get_prices(): array {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get('settings/price/collection/');
        return array_map(function ($item) { return Price::from_json($item); }, $json['data']);
    }
    public function get_price(string $id): Price {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get('settings/price/' . $id . '/');
        return Price::from_json($json);
    }
    public function get_customers(?array $params = []): array {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get('customer/collection/', $params);
        return array_map(function ($item) { return Customer::from_json($item); }, $json['data']);
    }
    public function post_customer(Customer|string $customer): Customer {
        $http = new HTTP($this->endpoint, $this->api_key);
        if (is_string($customer)) {
            $json = $http->http_post('customer/', $customer);
        } else {
            $json = $http->http_post('customer/', json_encode(['customer' => $customer->to_dict()], JSON_FORCE_OBJECT));
        }
        return Customer::from_json($json);
    }
    public function post_address(Address $address): Address {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_post('address/', json_encode(['address' => $address->to_dict()], JSON_FORCE_OBJECT));
        return Address::from_json($json);
    }
    public function get_address(string $id): Address {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get('address/' . $id . '/');
        return Address::from_json($json);
    }
    public function post_subscription(Payload\SubscriptionPayload $subscription): Payload\EditSubscriptionResult {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_post('subscription/', json_encode($subscription->to_dict(), JSON_FORCE_OBJECT));
        return Payload\EditSubscriptionResult::from_json($json);
    }
    public function put_subscription(Payload\SubscriptionPayload $subscription): Payload\EditSubscriptionResult {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_put(sprintf('subscription/%s/', $subscription->subscription->id), $subscription->to_dict());
        return Payload\EditSubscriptionResult::from_json($json);
    }
    public function cancel_subscription(string $subscription): Payload\EditSubscriptionResult {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_post(sprintf('subscription/%s/cancel/', $subscription), "");
        return Payload\EditSubscriptionResult::from_json($json);
    }
    public function extend_subscription(string $subscription_id, Payload\SubscriptionExtension $extension): Payload\EditSubscriptionResult {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_post(sprintf('subscription/%s/extension/', $subscription_id), $extension->to_dict());
        return Payload\EditSubscriptionResult::from_json($json);
    }
    public function get_subscriptions(?array $params = []): array {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get_paged('subscription/collection/', $params);
        return array_map(function ($item) { return Subscription::from_json($item); }, $json['data']);
    }
    public function get_subscription_invoices(string $subscription, ?array $params = []): array {
        $http = new HTTP($this->endpoint, $this->api_key);
        $json = $http->http_get_paged('subscription/' . $subscription . '/invoice/collection/', $params);
        return array_map(function ($item) { return Invoice::from_json($item); }, $json['data']);
    }
}
