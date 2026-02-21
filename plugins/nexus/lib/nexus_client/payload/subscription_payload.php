<?php
declare(strict_types=1);
namespace Nexus\Payload;
class SubscriptionPayload {
    public \Nexus\Subscription $subscription;
    public string $payment_plugin;
    public ?string $invoicing_plugin = null;
    public string $language;
    public ?array $metadata = null;
    
    public static function from_json(array $json): SubscriptionPayload {
        $result = new SubscriptionPayload();
        $result->subscription = \Nexus\Subscription::from_json($json['subscription']);
        foreach (['payment_plugin', 'invoicing_plugin', 'language', 'metadata'] as $key) {
            if (isset($json['payment'][$key])) {
                $result->$key = $json['payment'][$key];
            }
        }
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [
            'subscription' => $this->subscription->to_dict(),
            'payment' => []
        ];
        foreach (['payment_plugin', 'invoicing_plugin', 'language', 'metadata'] as $key) {
            if ($this->$key !== null) {
                $to_encode['payment'][$key] = $this->$key;
            }
        }
        return $to_encode;
    }
}