<?php
declare(strict_types=1);
namespace Nexus\Payload;
class EditSubscriptionResult {
    public \Nexus\Subscription $subscription;
    public ?\Nexus\Invoice $invoice = null;
    public ?\Nexus\Payload\CustomerAction $customer_action = null;
    
    public static function from_json(array $json): EditSubscriptionResult {
        $result = new EditSubscriptionResult();
        $result->subscription = \Nexus\Subscription::from_json($json['subscription']);
        if (isset($json['invoice'])) $result->invoice = \Nexus\Invoice::from_json($json['invoice']);
        if (isset($json['customer_action'])) $result->customer_action = CustomerAction::from_json($json['customer_action']);
        return $result;
    }
    public function to_dict(): array {
        $to_encode = [
            'subscription' => $this->subscription->to_dict(),
        ];
        if ($this->invoice !== null) $to_encode['invoice'] = $this->invoice->to_dict();
        if ($this->customer_action !== null) $to_encode['customer_action'] = $this->customer_action->to_dict();
        return $to_encode;
    }
}