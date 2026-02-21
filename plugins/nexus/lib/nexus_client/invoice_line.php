<?php
declare(strict_types=1);
namespace Nexus;
class InvoiceLine {
    public ?string $id = null;
    public ?string $invoice = null;
    public ?int $sort_index = null;
    public ?string $price = null;
    public ?int $item_price = null;
    public ?int $item_count = null;
    public ?int $tax_rate = null;
    public ?string $description = null;
    public ?bool $recurring = null;
    public static function from_json(array $json): InvoiceLine {
        $result = new InvoiceLine();
        foreach (['id', 'invoice', 'sort_index', 'price', 'item_price', 'item_count', 'tax_rate', 'description', 'recurring'] as $key) {
            if (isset($json[$key])) {
                $result->$key = $json[$key];
            }
        }
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [ ];
        foreach (['id', 'invoice', 'sort_index', 'price', 'item_price', 'item_count', 'tax_rate', 'description', 'recurring'] as $key) {
            if ($this->$key !== null) {
                $to_encode[$key] = $this->$key;
            }
        }
        return $to_encode;
    }
}