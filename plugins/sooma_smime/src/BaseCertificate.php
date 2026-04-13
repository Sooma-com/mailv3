<?php
declare(strict_types=1);
namespace Sooma\Smime;

abstract class BaseCertificate implements Certificate
{
    private string|null $certificate_email = null;
    private int|null $certificate_not_before = null; 
    private int|null $certificate_not_after = null;
    public function certificate_email(): string {
        if ($this->certificate_email === null) {
            $cert_data = openssl_x509_parse($this->certificate());
            if (isset($cert_data['extensions']) && isset($cert_data['extensions']['subjectAltName']) && str_starts_with($cert_data['extensions']['subjectAltName'], 'email:')) {
                $this->certificate_email = substr($cert_data['extensions']['subjectAltName'], strlen('email:'));
            } else if (isset($cert_data['subject']) && isset($cert_data['subject']['emailAddress'])) {
                $this->certificate_email = $cert_data['subject']['emailAddress'];
            } else {
                throw new Exception('Certificate email not found');
            }
        }
        return $this->certificate_email;
    }
    public function certificate_not_before(): int {
        if ($this->certificate_not_before === null) {
            $cert_data = openssl_x509_parse($this->certificate());
            $this->certificate_not_before = $cert_data['validFrom_time_t'];
        }
        return $this->certificate_not_before;
    }
    public function certificate_not_after(): int {
        if ($this->certificate_not_after === null) {
            $cert_data = openssl_x509_parse($this->certificate());
            $this->certificate_not_after = $cert_data['validTo_time_t'];
        }
        return $this->certificate_not_after;
    }
}