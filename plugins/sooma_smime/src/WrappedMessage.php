<?php
namespace Sooma\Smime;


// Wrapped message delegates all \Mail_mime methods to the inner (wrapped) message.
class WrappedMessage extends \Mail_mime {
    protected \Mail_mime $inner;
    public function __construct(\Mail_mime $inner)
    {
        $this->inner = $inner;
    }
    public function setParam($name, $value) { return $this->inner->setParam($name, $value); }
    public function getParam($name) { return $this->inner->getParam($name); }
    public function setTXTBody($data, $isfile = false, $append = false) { return $this->inner->setTXTBody($data, $isfile, $append); }
    public function getTXTBody() { return $this->inner->getTXTBody(); }
    public function setHTMLBody($data, $isfile = false) { return $this->inner->setHTMLBody($data, $isfile); }
    public function getHTMLBody() { return $this->inner->getHTMLBody(); }
    public function setCalendarBody($data, $isfile = false, $append = false,
        $method = 'request', $charset = 'UTF-8', $encoding = 'quoted-printable'
    ) { return $this->inner->setCalendarBody($data, $isfile, $append, $method, $charset, $encoding); }
    public function getCalendarBody() { return $this->inner->getCalendarBody(); }
    public function addHTMLImage($file,
        $c_type = 'application/octet-stream',
        $name = '',
        $isfile = true,
        $content_id = null
    ) { return $this->inner->addHTMLImage($file, $c_type, $name, $isfile, $content_id); }
    public function addAttachment($file,
        $c_type      = 'application/octet-stream',
        $name        = '',
        $isfile      = true,
        $encoding    = 'base64',
        $disposition = 'attachment',
        $charset     = '',
        $language    = '',
        $location    = '',
        $n_encoding  = null,
        $f_encoding  = null,
        $description = '',
        $h_charset   = null,
        $add_headers = array()
    ) { return $this->inner->addAttachment($file, $c_type, $name, $isfile, $encoding, $disposition, $charset, $language, $location, $n_encoding, $f_encoding, $description, $h_charset, $add_headers); }
    public function isMultipart() { return $this->inner->isMultipart(); }
    public function getMessage($separation = null, $params = null, $headers = null,
        $overwrite = false
    ) { return $this->inner->getMessage($separation, $params, $headers, $overwrite); }
    public function getMessageBody($params = null) { return $this->inner->getMessageBody($params); }
    public function saveMessage($filename, $params = null, $headers = null, $overwrite = false) { return $this->inner->saveMessage($filename, $params, $headers, $overwrite); }
    public function txtHeaders($xtra_headers = null, $overwrite = false, $skip_content = false) { return $this->inner->txtHeaders($xtra_headers, $overwrite, $skip_content); }
    public function setContentType($type, $params = array()) { return $this->inner->setContentType($type, $params); }
    public function setSubject($subject) { return $this->inner->setSubject($subject); }
    public function setFrom($email) { return $this->inner->setFrom($email); }
    public function addTo($email) { return $this->inner->addTo($email); }
    public function addCc($email) { return $this->inner->addCc($email); }
    public function addBcc($email) { return $this->inner->addBcc($email); }
    public function encodeRecipients($recipients) { return $this->inner->encodeRecipients($recipients); }
    public function encodeHeader($name, $value, $charset, $encoding) { return $this->inner->encodeHeader($name, $value, $charset, $encoding); }
    public static function isError($data) { return \Mail_mime::isError($data); }
    public static function raiseError($message) { return \Mail_mime::raiseError($message); }
    public function headers($xtra_headers = null, $overwrite = false, $skip_content = false) { return $this->inner->headers($xtra_headers, $overwrite, $skip_content); }
    public function saveMessageBody($filename, $params = null) { return $this->inner->saveMessageBody($filename, $params); }
    public function get($params = null, $filename = null, $skip_head = false) { return $this->inner->get($params, $filename, $skip_head); }
}