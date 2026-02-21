<?php
declare(strict_types=1);
namespace Nexus;
class Product {
    public string $id;
    public string $owner;
    public string $reference;
    public string $name;
    public string $description;
    public string $tax_category;
    public bool $active;
    public string $provisioning_plugin;
    public array $metadata;
    public string $created;
    public ?Product $upgrade_to = null;

    public static function from_json(array $json): Product {
        $result = new Product();
        $result->id = $json['id'];
        $result->owner = $json['owner'];
        $result->reference = $json['reference'];
        $result->name = $json['name'];
        $result->description = $json['description'];
        $result->tax_category = $json['tax_category'];
        $result->active = $json['active'];
        $result->provisioning_plugin = $json['provisioning_plugin'];
        $result->metadata = $json['metadata'];
        $result->created = $json['created'];
        return $result;
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