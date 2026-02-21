<?php
declare(strict_types=1);
namespace Nexus;
class Customer {
    public ?string $id = null;
    public string $owner;
    public string $name;
    public string $email;
    public string $currency;
    public ?string $tax_address = null;
    public string $tax_id;
    public ?string $tax_id_type = null;
    public array $metadata;
    public string $created;
    public static function from_json(array $json): Customer {
        $result = new Customer();
        foreach (['id', 'owner', 'name', 'email', 'currency', 'tax_address', 'tax_id', 'tax_id_type', 'metadata', 'created'] as $key) {
            if (isset($json[$key])) {
                $result->$key = $json[$key];
            }
        }
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [];
        foreach (['id', 'owner', 'name', 'email', 'currency', 'tax_address', 'tax_id', 'tax_id_type', 'metadata', 'created'] as $key) {
            if (isset($this->$key) && $this->$key !== null) {
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