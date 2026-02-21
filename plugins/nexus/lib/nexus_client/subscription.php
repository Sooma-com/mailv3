<?php
declare(strict_types=1);
namespace Nexus;
class Subscription {
    public ?string $id = null;
    public ?string $customer = null;
    public ?string $price = null;
    public ?string $currency = null;
    public ?array $product_config = null;
    public ?string $provisioning = null;
    public ?string $status = null;
    public ?string $online_success_return_url = null;
    public ?string $event_callback_url = null;
    public ?string $ends = null;
    public ?array $metadata = null;
    public ?string $created = null;

    public static function from_json(array $json): Subscription {
        $result = new Subscription();
        foreach (['id', 'customer', 'price', 'currency', 'product_config', 'provisioning', 'status', 'online_success_return_url', 'event_callback_url', 'ends', 'metadata', 'created'] as $key) {
            if (isset($json[$key])) {
                $result->$key = $json[$key];
            }
        }
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [];
        foreach (['id', 'customer', 'price', 'currency', 'product_config', 'provisioning', 'status', 'online_success_return_url', 'event_callback_url', 'ends', 'metadata', 'created'] as $key) {
            if ($this->$key !== null) {
                $to_encode[$key] = $this->$key;
            }
        }
        return $to_encode;
    }
    public function get_metadata($key) {
        $parts = explode('.', $key);
        $metadata = $this->metadata;
        foreach ($parts as $part) {
            if (!isset($metadata[$part])) return null;
            $metadata = $metadata[$part];
        }
        return $metadata;
    }
}