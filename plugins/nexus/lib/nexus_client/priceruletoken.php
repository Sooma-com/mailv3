<?php
declare(strict_types=1);
namespace Nexus;
class PriceRuleToken {
    public string $type;
    public int $fixed_precision_value;
    public int $decimal_digits;
    public array $json_value;

    public static function from_json(array $json): PriceRuleToken {
        $type = array_keys($json)[0];
        $result = new PriceRuleToken();
        $result->type = $type;
        if ($type == 'OperandNumber') {
            $result->fixed_precision_value = $json[$type]['fixed_precision_value'];
            $result->decimal_digits = $json[$type]['decimal_digits'];
        }
        if ($type == 'OperandJson') {
            $result->json_value = $json[$type];
        }
        return $result;
    }
    public function __toString(): string {
        switch ($this->type) {
            case 'LeftParenthesis':
                return '(';
            case 'RightParenthesis':
                return ')';
            case 'OperatorAddition':
                return '+';
            case 'OperatorSubtraction':
                return '-';
            case 'OperatorMultiplication':
                return '*';
            case 'OperatorDivision':
                return '/';
            case 'OperandNumber':
                if ($this->decimal_digits == 0) {
                    return (string)$this->fixed_precision_value;
                } else {
                    return preg_replace("_(\d{{$this->decimal_digits}})\$_", '.$1', sprintf("%0{$this->decimal_digits}d", $this->fixed_precision_value));
                }
            case 'OperandJson':
                return json_encode($this->json_value);
            default:
                throw new Exception('Unknown price rule token type: ' . $this->type);
        }
    }
}