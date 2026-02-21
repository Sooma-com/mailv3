<?php
declare(strict_types=1);
namespace Nexus;
class Invoice {
    public ?string $id = null;
    public ?string $subscription = null;
    public ?string $previous_invoice = null;
    public ?string $payment_plugin = null;
    public ?string $invoicing_plugin = null;
    public ?string $currency = null;
    public ?string $status = null;
    public ?string $locale = null;
    public ?array $metadata = null;
    public ?string $created = null;
    public ?array $lines = null;
    public static function from_json(array $json): Invoice {
        $result = new Invoice();
        foreach (['id', 'subscription', 'previous_invoice', 'payment_plugin', 'invoicing_plugin', 'currency', 'status', 'locale', 'metadata', 'created'] as $key) {
            if (isset($json[$key])) {
                $result->$key = $json[$key];
            }
        }
        if (isset($json['lines'])) {
            $result->lines = array_map(function ($item) { return InvoiceLine::from_json($item); }, $json['lines']);
        }
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [ ];
        foreach (['id', 'subscription', 'previous_invoice', 'payment_plugin', 'invoicing_plugin', 'currency', 'status', 'locale', 'metadata', 'created'] as $key) {
            if ($this->$key !== null) {
                $to_encode[$key] = $this->$key;
            }
        }
        if ($this->lines !== null) {
            $to_encode['lines'] = array_map(function ($item) { return $item->to_dict(); }, $this->lines);
        }
        return $to_encode;
    }
}