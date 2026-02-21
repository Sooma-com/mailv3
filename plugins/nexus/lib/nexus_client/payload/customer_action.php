<?php
declare(strict_types=1);
namespace Nexus\Payload;
class CustomerAction {
    const TYPE_REDIRECT = 'redirect';
    const TYPE_MBWAY = 'mbway';
    const TYPE_MULTIBANCO = 'multibanco';
    const TYPE_NONE = 'none';

    public string $type;
    public ?string $entity = null;
    public ?string $reference = null;
    public ?float $value = null;

    public ?string $url = null;

    
    public static function from_json(array $json): CustomerAction {
        if (is_string($json)) $json = json_decode($json, true);
        $result = new CustomerAction();
        $type = array_keys($json)[0];
        if ($type == self::TYPE_MBWAY || $type == self::TYPE_NONE) {
            $result->type = $type;
        } else if ($type == self::TYPE_REDIRECT) {
            $result->type = self::TYPE_REDIRECT;
            $result->url = $json[self::TYPE_REDIRECT]['url'];
        } else if ($type == self::TYPE_MULTIBANCO) {
            $result->type = self::TYPE_MULTIBANCO;
            $result->entity = $json[self::TYPE_MULTIBANCO]['entity'];
            $result->reference = $json[self::TYPE_MULTIBANCO]['reference'];
            $result->value = $json[self::TYPE_MULTIBANCO]['value'];
        } else {
            throw new \Nexus\Exception('Invalid customer action type');
        }

        return $result;
    }
    public function to_dict(): array {
        if ($this->type == self::TYPE_REDIRECT || $this->type == self::TYPE_MBWAY || $this->type == self::TYPE_NONE) {
            $payload = [];
        } else if ($this->type == self::TYPE_MULTIBANCO) {
            $payload = [
                'entity' => $this->entity,
                'reference' => $this->reference,
                'value' => $this->value,
            ];
        } else {
            throw new \Nexus\Exception('Invalid customer action type');
        }

        return [ $this->type => $payload ];
    }
}