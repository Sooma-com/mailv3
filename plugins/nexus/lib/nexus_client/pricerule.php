<?php
declare(strict_types=1);
namespace Nexus;
class PriceRule {
    public string $notation;
    public array $tokens;

    public static function from_json(array $json): PriceRule {
        $result = new PriceRule();
        $result->notation = $json['notation'];
        $result->tokens = array_map(
            function ($item) { return PriceRuleToken::from_json($item); },
            $json['tokens']
        );
        return $result;
    }
    public function __toString(): string {
        if ($this->notation == 'Infix') {
            return implode(' ', array_map(function ($token) { return $token->__toString(); }, $this->tokens));
        }
        throw new Exception('Unknown price rule notation: ' . $this->notation);
    }
}