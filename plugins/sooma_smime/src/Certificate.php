<?php
declare(strict_types=1);
namespace Sooma\Smime;

interface Certificate {
    public function certificate(): \OpenSSLCertificate;
    public function certificate_email(): string;
    public function sign_message(\Mail_mime $message): \Mail_mime;
}