<?php
declare(strict_types=1);
namespace Nexus;
class HTTP {
    private string $endpoint;
    private string $api_key;
    public function __construct(string $endpoint, string $api_key) {
        $this->endpoint = $endpoint[strlen($endpoint) - 1] == '/' ? $endpoint : $endpoint . '/';
        $this->api_key = $api_key;
    }
    public function ch(string $url) {
        $url = $this->endpoint . $url;
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        return $ch;
    }
    public function parse_response(string $text_response) {
        $response = json_decode($text_response, true);
        if (!$response) throw new Exception("Unparseable JSON response from Nexus: " . $text_response);
        if (!$response['success']) throw new APIError("Nexus API error: " . $response['error']['message']);
        return $response['data'];
    }
    public function http_get(string $url, array $params = []) {
        if (count($params) > 0) $url .= (strpos($url, '?') === false ? '?' : '&') . http_build_query($params);
        $ch = $this->ch($url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Accept: application/json",
            "Authorization: Basic " . base64_encode($this->api_key . ":"),
        ]);
        $response = curl_exec($ch);
        curl_close($ch);
        return $this->parse_response($response);
    }
    public function http_get_paged(string $url, array $params = []) {
        $collected_data = [];
        $page = 1;
        while (true) {
            $params['page'] = $page;
            $response = $this->http_get($url, $params);
            $collected_data = array_merge($collected_data, $response['data']);
            if ($page >= (@$response['page_count'] ?? 0) || count($response['data']) == 0) {
                return [ 'data' => $collected_data, 'page_count' => $response['page_count'] ];
            }
            $page++;
        }
    }
    public function http_post(string $url, string|array|object $data, array $params = []) {
        if (count($params) > 0) $url .= (strpos($url, '?') === false ? '?' : '&') . http_build_query($params);
        $ch = $this->ch($url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Accept: application/json",
            "Content-Type: application/json",
            "Authorization: Basic " . base64_encode($this->api_key . ":"),
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, is_string($data) ? $data : json_encode($data, JSON_FORCE_OBJECT));
        $response = curl_exec($ch);
        curl_close($ch);
        return $this->parse_response($response);
    }
    public function http_put(string $url, string|array|object $data, array $params = []) {
        if (count($params) > 0) $url .= (strpos($url, '?') === false ? '?' : '&') . http_build_query($params);
        $ch = $this->ch($url);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Accept: application/json",
            "Content-Type: application/json",
            "Authorization: Basic " . base64_encode($this->api_key . ":"),
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, is_string($data) ? $data : json_encode($data, JSON_FORCE_OBJECT));
        $response = curl_exec($ch);
        curl_close($ch);
        return $this->parse_response($response);
    }
}