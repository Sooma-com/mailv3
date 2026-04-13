<?php
namespace Sooma\Smime;

// Message wraps a \Mail_mime object and signs it with a certificate and private key at the very last moment before sending
// This is done by overriding get() and headers() to return data from the signed message
class Message extends WrappedMessage {
    private \OpenSSLCertificate $certificate;
    private \OpenSSLAsymmetricKey $private_key;
    private array $extra_certificates = [];
    private string|null $before_sign_source_code = null;
    private string|null $after_sign_source_code = null;

    public function __construct(\Mail_mime $inner, \OpenSSLCertificate|string $certificate, \OpenSSLCertificate|string $private_key, array $extra_certificates = [])
    {
        if (is_string($certificate)) {
            $value = openssl_x509_read($certificate);
            if ($value === false) {
                throw new SSLException('Failed to read certificate');
            }
            $certificate = $value;
        }
        if (is_string($private_key)) {
            $value = openssl_pkey_get_private($private_key);
            if ($value === false) {
                throw new SSLException('Failed to read private key');
            }
            $private_key = $value;
        }
        $this->certificate = $certificate;
        $this->private_key = $private_key;
        $this->extra_certificates = $extra_certificates;
        parent::__construct($inner);
    }
    public function signMessage(): void {
        $headers = array_reduce(
            array_map(
                function($name, $value) { return "$name: $value\r\n"; },
                array_keys(parent::headers()),
                array_values(parent::headers())
            )
            , function($acc, $h) { return $acc . $h; }
        );
        $body = parent::get();
        $before_sign_source_code = $headers . "\r\n" . $body;
        if ($before_sign_source_code === $this->before_sign_source_code) return;
        $this->before_sign_source_code = $before_sign_source_code;
        $inputFile  = tempnam(sys_get_temp_dir(), 'smime_in_');
        $outputFile = tempnam(sys_get_temp_dir(), 'smime_out_');
        $extraCertsFile = null;
        try {
            file_put_contents($inputFile, $headers . "\r\n" . $body);
            if (!empty($this->extra_certificates)) {
                $extraCertsFile = tempnam(sys_get_temp_dir(), 'smime_extra_');
                file_put_contents($extraCertsFile, implode("\n", $this->extra_certificates));
            }
            $headers_to_prepend = parent::headers();
            foreach (array_filter(array_keys($headers_to_prepend), function($key) { 
                return strtolower($key) === 'content-type' || strtolower($key) === 'mime-version';
            }) as $key) unset($headers_to_prepend[$key]);
            $signed = openssl_pkcs7_sign(
                $inputFile,
                $outputFile,
                $this->certificate,
                [$this->private_key, ""],
                $headers_to_prepend,
                PKCS7_DETACHED,
                $extraCertsFile
            );
            if (!$signed) {
                throw new SSLException( 'openssl_pkcs7_sign() failed' );
            }
            $this->after_sign_source_code = file_get_contents($outputFile);
        } catch (Exception $e) {
            \rcube::write_log('error', 'Unable to sign message, proceeding without signing: ' . $e->getMessage());
            $this->after_sign_source_code = null;
        } finally {
            foreach (array_filter([
                $inputFile, $outputFile, $extraCertsFile
            ]) as $f) {
                @unlink($f);
            }
        }
    }
    public function headers($xtra_headers = null, $overwrite = false, $skip_content = false) {
        parent::headers($xtra_headers, $overwrite, $skip_content); // Affect the wrapped message if this is a write operation
        $this->signMessage();
        if ($this->after_sign_source_code === null) {
            return parent::headers($xtra_headers, $overwrite, $skip_content);
        }
        $headers = array_reduce(
            explode("\n", explode("\n\n", $this->after_sign_source_code, 2)[0]), 
            function ($acc, $line) {
                list($name, $value) = explode(':', $line, 2);
                if ($value[0] == ' ') $value = substr($value, 1);
                $acc[$name] = $value;
                return $acc;
            }, 
            []
        );

        if ($xtra_headers !== null) {
            if ($overwrite) {
                foreach ($xtra_headers as $key => $value) {
                    if (is_null($value)) unset($headers[$key]);
                }
                $xtra_headers = array_filter($xtra_headers, function ($value) { return !is_null($value); });
            }
            $xtra_headers = $this->inner->encodeHeaders($xtra_headers);
            if ($overwrite) {
                $headers = array_merge($headers, $xtra_headers);
            } else {
                $headers = array_merge($xtra_headers, $headers);
            }
        }

        return $headers;
    }
    public function txtHeaders($xtra_headers = null, $overwrite = false, $skip_content = false)
    {
        $this->signMessage();
        if ($this->after_sign_source_code === null) {
            return parent::txtHeaders($xtra_headers, $overwrite, $skip_content);
        }
        $headers = $this->headers($xtra_headers, $overwrite, $skip_content);

        // Place Received: headers at the beginning of the message
        // Spam detectors often flag messages with it after the Subject: as spam
        if (isset($headers['Received'])) {
            $received = $headers['Received'];
            unset($headers['Received']);
            $headers = array('Received' => $received) + $headers;
        }

        $ret = '';
        $eol = $this->build_params['eol'];

        foreach ($headers as $key => $val) {
            if (is_array($val)) {
                foreach ($val as $value) {
                    $ret .= "$key: $value" . $eol;
                }
            } else {
                $ret .= "$key: $val" . $eol;
            }
        }

        return $ret;
    }  
    public function get($params = null, $filename = null, $skip_head = false) {
        if ($params !== null || $filename !== null || $skip_head !== false) {
            return parent::get($params, $filename, $skip_head);
        }
        $this->signMessage();
        if ($this->after_sign_source_code === null) {
            return parent::get($params, $filename, $skip_head);
        }
        return explode("\n\n", $this->after_sign_source_code, 2)[1];
    }

}