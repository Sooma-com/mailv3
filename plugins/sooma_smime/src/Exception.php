<?php
declare(strict_types=1);
namespace Sooma\Smime;

class Exception extends \Exception {
}
class SSLException extends Exception {
    public array $ssl_errors = [];
    public function __construct(string $message) {
        parent::__construct($message);
        $this->ssl_errors = self::get_openssl_errors();
    }
    public static function get_openssl_errors(): array {
        $errors = [];
        while ($msg = openssl_error_string()) {
            $errors[] = $msg;    
        }    
        return $errors;
    }
}
class DBException extends Exception {}