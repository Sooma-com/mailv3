<?php
declare(strict_types=1);
namespace Nexus;
class Address {
    public ?string $id = null;
    public ?string $city = null;
    public string $country;
    public ?string $address_line_1 = null;
    public ?string $address_line_2 = null;
    public ?string $postal_code = null;
    public ?string $state = null;
    public ?string $company_name = null;
    public ?string $recipient_name = null;
    public static function from_json(array $json): Address {
        $result = new Address();
        foreach (['id', 'city', 'address_line_1', 'address_line_2', 'postal_code', 'state', 'company_name', 'recipient_name'] as $key) {
            if (isset($json[$key])) {
                $result->$key = $json[$key];
            }
        }
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [
            'country' => $this->country,
        ];
        foreach (['id', 'city', 'address_line_1', 'address_line_2', 'postal_code', 'state', 'company_name', 'recipient_name'] as $key) {
            if ($this->$key !== null) {
                $to_encode[$key] = $this->$key;
            }
        }
        return $to_encode;
    }
}