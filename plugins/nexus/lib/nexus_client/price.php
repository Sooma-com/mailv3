<?php
declare(strict_types=1);
namespace Nexus;
class Price {
    public string $id;
    public string $product;
    public bool $active;
    public string $reference;
    public string $default_currency;
    public string $name;
    public ?PriceRule $one_time_rule;
    public ?PriceRule $recurring_rule;
    public array $grace_period;
    public array $trial_period;
    public ?array $recurring_interval;
    public ?array $metadata;
    public string $created;

    public static function from_json(array $json): Price {
        $result = new Price();
        $result->id = $json['id'];
        $result->product = $json['product'];
        $result->active = $json['active'];
        $result->reference = $json['reference'];
        $result->default_currency = $json['default_currency'];
        $result->name = $json['name'];
        $result->one_time_rule = $json['one_time_rule'] ? PriceRule::from_json($json['one_time_rule']) : null;
        $result->recurring_rule = $json['recurring_rule'] ? PriceRule::from_json($json['recurring_rule']) : null;
        $result->grace_period = $json['grace_period'];
        $result->trial_period = $json['trial_period'];
        $result->recurring_interval = $json['recurring_interval'];
        $result->metadata = $json['metadata'];
        $result->created = $json['created'];
        return $result;
    }
}