<?php
declare(strict_types=1);
namespace Sooma\Smime;

class DBCertificate extends BaseCertificate
{
    const IMPORT_SUCCESS = 'IMPORT_SUCCESS';
    const IMPORT_FILE_NOT_FOUND = 'IMPORT_FILE_NOT_FOUND';
    const IMPORT_FILE_NOT_SUPPORTED = 'IMPORT_FILE_NOT_SUPPORTED';
    const IMPORT_PARSE_ERROR = 'IMPORT_PARSE_ERROR';
    const IMPORT_WRONG_PASSWORD = 'IMPORT_WRONG_PASSWORD';
    const IMPORT_NO_PRIVATE_KEY = 'IMPORT_NO_PRIVATE_KEY';
    const IMPORT_NO_CERTIFICATE = 'IMPORT_NO_CERTIFICATE';

    public string|null $id = null;
    public string|null $owner = null;
    public string $certificate;
    public string|null $private_key = null;
    public array|null $extra_certificates = null;


    public function import_key(\sooma_smime $plugin, string $file, string $password): Certificate|string {
        $file_contents = file_get_contents($file);
        if ($file_contents === false) {
            return self::IMPORT_FILE_NOT_FOUND;
        }
        $file_format = null;
        if (str_contains($file_contents, '-----BEGIN ENCRYPTED PRIVATE KEY-----')) $file_format = 'pkcs8_encrypted';
        if (str_contains($file_contents, '-----BEGIN PRIVATE KEY-----'))           $file_format = 'pkcs8';
        if (str_contains($file_contents, '-----BEGIN RSA PRIVATE KEY-----'))       $file_format = 'pkcs1';
        if (str_contains($file_contents, '-----BEGIN EC PRIVATE KEY-----'))        $file_format = 'pkcs1_ec';
        if (str_contains($file_contents, 'Proc-Type: 4,ENCRYPTED'))                $file_format = 'pkcs1_encrypted';
        if (is_null($file_format)) switch (self::certificateFormat($file_contents)) {
            case 'private_key': $file_format = 'pkcs8_der'; break;
            case 'pkcs12': $file_format = 'pkcs12'; break;
            default: $file_format = null; break;
        };
        if (is_null($file_format)) return self::IMPORT_FILE_NOT_SUPPORTED;
        switch ($file_format) {
            case 'pkcs8_encrypted':
            case 'pkcs8':
            case 'pkcs1':
            case 'pkcs1_ec':
                return $this->import_key_pem($plugin, $file_contents, $password);
            case 'pkcs12':
                return $this->import_key_pkcs12($plugin, $file_contents, $password);
        }
        return self::IMPORT_FILE_NOT_SUPPORTED;
    }
    public function import_key_pem(\sooma_smime $plugin, string $data, string $password): Certificate|string {
        if (str_contains($data, '-----BEGIN PRIVATE KEY-----') ||
            str_contains($data, '-----BEGIN ENCRYPTED PRIVATE KEY-----') ||
            str_contains($data, '-----BEGIN RSA PRIVATE KEY-----') ||
            str_contains($data, '-----BEGIN EC PRIVATE KEY-----')) {
            SSLException::get_openssl_errors();
            $private_key = openssl_pkey_get_private($data, $password);
            $openssl_errors = SSLException::get_openssl_errors();
            if (!$private_key) {
                if (self::openssl_errors_match($openssl_errors, 'bad decrypt')) return self::IMPORT_WRONG_PASSWORD;
                return self::IMPORT_PARSE_ERROR;
            }
            if (!openssl_pkey_export($private_key, $private_key_pem)) {
                return self::IMPORT_PARSE_ERROR;
            }
            $this->private_key = $private_key_pem;
            return $this;
        }
        return self::IMPORT_FILE_NOT_SUPPORTED;
    }
    public function import_key_pkcs12(\sooma_smime $plugin, string $data, string $password): Certificate|string {
        SSLException::get_openssl_errors();
        $result = openssl_pkcs12_read($data, $cert, $password);
        if ($result === false) {
            return self::IMPORT_PARSE_ERROR;
        }
        if (isset($cert['pkey'])) {
            $this->private_key = $cert['pkey'];
            return $this;
        }
        return self::IMPORT_NO_PRIVATE_KEY;
    }
    public static function import(\sooma_smime $plugin, string $file, string $password): Certificate|string
    {
        $file_contents = file_get_contents($file);
        if ($file_contents === false) {
            return self::IMPORT_FILE_NOT_FOUND;
        }
        if (ord($file_contents[0]) == 0x30) {
            switch (self::certificateFormat($file_contents)) {
                case 'x509':
                    $file_contents = sprintf("-----BEGIN CERTIFICATE-----\n%s-----END CERTIFICATE-----", chunk_split(base64_encode($file_contents), 64, "\n"));
                    return self::import_pem($plugin, $file_contents, $password);
                case 'pkcs12':
                    return self::import_pkcs12($plugin, $file_contents, $password);
                case 'pkcs7':
                    return self::import_pkcs7($plugin, $file_contents, $password);
                default:
                    return self::IMPORT_FILE_NOT_SUPPORTED;
            }
        } else if (strpos($file_contents, '-----BEGIN CERTIFICATE-----') !== false) {
            return self::import_pem($plugin, $file_contents, $password);
        } else {
            return self::IMPORT_FILE_NOT_SUPPORTED;
        }
    }
    static function certificateFormat(string $bytes): string|false
    {
        if (($bytes[0] ?? '') !== "\x30") return false;
        $offset = match ($bytes[1] ?? '') {
            "\x81" => 3,  // 0x30 0x81 <len>
            "\x82" => 4,  // 0x30 0x82 <len_hi> <len_lo>
            default => 2, // 0x30 <short_len>
        };
        $inner = $bytes[$offset] ?? '';

        // X.509 certificate: next element is SEQUENCE (TBSCertificate)
        if ($inner === "\x30") return 'x509';

        // PKCS#8 private key or PKCS#12: next element is INTEGER (version)
        if ($inner === "\x02") {
            $version = ord($bytes[$offset + 2] ?? "\xff");
            if ($version === 0) return 'private_key'; // PKCS#8 version is always 0
            if ($version === 3) return 'pkcs12';      // PKCS#12 version is always 3
        }
        if ($inner === "\x06") return 'pkcs7';

        return false;
    }

    public static function import_pkcs12(\sooma_smime $plugin, string $data, string $password): Certificate|string {
        SSLException::get_openssl_errors();
        $result = openssl_pkcs12_read($data, $cert, $password);
        if ($result === false) {
            return self::IMPORT_PARSE_ERROR;
        }
        if (!isset($cert['cert'])) {
            return self::IMPORT_NO_CERTIFICATE;
        }
        $result = new DBCertificate($cert['cert']);
        if (isset($cert['pkey'])) {
            $result->private_key = $cert['pkey'];
        }
        if (isset($cert['extracerts'])) {
            $result->extra_certificates = $cert['extracerts'];
        }
        return $result;
    }
    public static function import_pem(\sooma_smime $plugin, string $data, string $password): Certificate|string {
        SSLException::get_openssl_errors();
        $cert = openssl_x509_read($data);
        if ($cert === false) {
            return self::IMPORT_PARSE_ERROR;
        }
        if (!openssl_x509_export($cert, $cert_pem)) {
            return self::IMPORT_PARSE_ERROR;
        }
        $cert_data = openssl_x509_parse($cert);
        if ($cert_data === false) {
            return self::IMPORT_PARSE_ERROR;
        }
        $result = new DBCertificate($cert_pem);
        if (str_contains($data, '-----BEGIN PRIVATE KEY-----') ||
            str_contains($data, '-----BEGIN ENCRYPTED PRIVATE KEY-----') ||
            str_contains($data, '-----BEGIN RSA PRIVATE KEY-----') ||
            str_contains($data, '-----BEGIN EC PRIVATE KEY-----')) {
            SSLException::get_openssl_errors();
            $private_key = openssl_pkey_get_private($data, $password);
            $openssl_errors = SSLException::get_openssl_errors();
            if (!$private_key) {
                if (self::openssl_errors_match($openssl_errors, 'bad decrypt')) return self::IMPORT_WRONG_PASSWORD;
                return self::IMPORT_PARSE_ERROR;
            }
            if (!openssl_pkey_export($private_key, $private_key_pem)) {
                return self::IMPORT_PARSE_ERROR;
            }
            $result->private_key = $private_key_pem;
        }
        return $result;
    }
    public static function openssl_errors_match(array $errors, string $pattern): bool {
        foreach ($errors as $error) {
            if (strpos($error, $pattern) !== false) {
                return true;
            }
        }
        return false;
    }
    public function __construct(string $certificate) {
        $this->certificate = $certificate;
    }
    public function certificate(): \OpenSSLCertificate {
        $result = openssl_x509_read($this->certificate);
        if ($result === false) throw new SSLException('Failed to read certificate');
        return $result;
    }
    static function create_from_row(array $row): DBCertificate {
        $certificate = new DBCertificate($row['certificate']);
        $certificate->id = $row['id'];
        $certificate->owner = $row['owner'];
        $certificate->private_key = $row['private_key'];
        $certificate->extra_certificates = json_decode($row['extra_certificates'], true);
        return $certificate;
    }
    public static function db_list(\sooma_smime $plugin, string $where = "true", int $page = 1, array $query_args = []): array {
        $pageSize = isset($query_args['page_size']) ? $query_args['page_size'] : 10;
        unset($query_args['page_size']);
        $query = <<<EOQ
SELECT 
 id,
 owner,
 email,
 certificate,
 private_key,
 CASE WHEN extra_certificates IS NULL THEN 'null' ELSE array_to_json(extra_certificates) END AS extra_certificates
FROM sooma_smime.certificate
WHERE

EOQ;
        $query .= $where;
        $result_count = $plugin->db_query_row(<<<EOQ
SELECT COUNT(*) AS count FROM ($query) AS subquery
EOQ, $query_args);
        if ($page > 0) {
            $page_count = (int) ceil($result_count['count'] / $pageSize);
        } else {
            $page_count = 1;
        }

        if ($page > 0) $query .= sprintf(' LIMIT %d OFFSET %d', $pageSize, ($page - 1) * $pageSize);
        return [ 'pages' => $page_count, 'result' => array_map([self::class, 'create_from_row'], $plugin->db_query_all($query, $query_args))];
    }
    public static function db_read(\sooma_smime $plugin, string $id): DBCertificate {
        $result = $plugin->db_query_row(<<<EOQ
SELECT 
 id,
 owner,
 email,
 certificate,
 private_key,
 CASE WHEN extra_certificates IS NULL THEN 'null' ELSE array_to_json(extra_certificates) END AS extra_certificates
FROM sooma_smime.certificate
WHERE id = ?
EOQ, [$id]);
        if ($result === null) throw new DBException(sprintf('Certificate %s not found', $id));
        return self::create_from_row($result);
    }
    public function db_update(\sooma_smime $plugin): void {
        $existing = self::db_read($plugin, $this->id);
        $delta = [];
        foreach (['owner', 'certificate', 'private_key'] as $field) {
            if ($this->$field !== $existing->$field) $delta[$field] = $this->$field;
        }
        if ($this->certificate_email() !== $existing->certificate_email()) $delta['email'] = $this->certificate_email();
        if (is_null($this->extra_certificates) && !is_null($existing->extra_certificates)) $delta['extra_certificates'] = null;
        if (
            count(array_diff($this->extra_certificates ?? [], $existing->extra_certificates ?? [])) +
            count(array_diff($existing->extra_certificates ?? [], $this->extra_certificates ?? [])) > 0
        ) {
            $delta['extra_certificates'] = $this->extra_certificates;
        }
        if (count($delta) == 0) return;
        $changes = implode(', ', array_map(function($key, $value) {
            if (is_null($value)) return sprintf('"%s" = NULL', $key);
            if (is_array($value)) return sprintf('"%s" = (SELECT array_agg(col) FROM (SELECT jsonb_array_elements_text(?)::text AS col) AS subquery)', $key);
            return sprintf('"%s" = ?', $key);
        }, array_keys($delta), array_values($delta)));
        $values = array_merge(...array_map(function($value) {
            if (is_array($value)) return [ json_encode($value) ];
            return [$value];
        }, array_values($delta)));
        $values[] = $this->id;
        $plugin->db_exec(<<<EOQ
UPDATE sooma_smime.certificate SET $changes WHERE id = ?
EOQ, $values);
    }
    public function db_upsert(\sooma_smime $plugin): void {
        $existing = $plugin->db_query_row(<<<EOQ
SELECT id
FROM sooma_smime.certificate
WHERE
 certificate = ?
 AND owner = ?
EOQ
        , [$this->certificate, $this->owner]);
        if ($existing) {
            $existing = self::db_read($plugin, $existing['id']);
            foreach (['owner', 'certificate', 'private_key', 'extra_certificates'] as $field) {
                if (!is_null($this->$field)) $existing->$field = $this->$field;
            }
            $existing->db_update($plugin);

        } else {
            $values = [ 'LOWER(?)', '?', 'to_timestamp(?)', 'to_timestamp(?)', '?'];
            if ($this->private_key) {
                $values[] = '?';
            } else { $values[] = 'DEFAULT'; }
            if ($this->extra_certificates) {
                $values[] = '(SELECT array_agg(col) FROM (SELECT jsonb_array_elements_text(?)::text AS col) AS subquery)';
            } else { $values[] = 'DEFAULT'; }

            $query = sprintf(<<<EOQ
INSERT INTO sooma_smime.certificate (
    owner,
    email,
    not_before,
    not_after,
    certificate,
    private_key,
    extra_certificates
) VALUES (%s) RETURNING id
EOQ, implode(',', $values));
            $args = [$this->owner, $this->certificate_email(), $this->certificate_not_before(), $this->certificate_not_after(), $this->certificate];
            if ($this->private_key) {
                $args[] = $this->private_key;
            }
            if ($this->extra_certificates) {
                $args[] = json_encode($this->extra_certificates);
            }
            $id = $plugin->db_query_row($query, $args);
            if (!$id) { 
                throw new Exception('Failed to insert certificate. Insert query did not return an id.');
            }
            $this->id = $id['id'];
        }
    }
    public function db_delete(\sooma_smime $plugin): void {
        $plugin->db_exec(<<<EOQ
DELETE FROM sooma_smime.certificate WHERE id = ?
EOQ, [$this->id]);
    }
    public function sign_message(\Mail_mime $message): \Mail_mime {
        if (is_null($this->private_key)) throw new Exception('Unable to sign message: no private key');
        if (is_null($this->certificate)) throw new Exception('Unable to sign message: no certificate in certificate object');
        try {
            $message = new Message($message, $this->certificate, $this->private_key);
            return $message;
        } catch (SSLException $e) {
            $plugin->rc->output->command('display_message', 'Unable to sign message. Message will be sent without signing.', 'error');
            rcube::write_log('error', 'Unable to sign message: ' . $e->getMessage());
            return $message;
        }
    }
}