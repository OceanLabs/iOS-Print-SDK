Paying for and Submitting a Print Order
==============

If you don't want to use the checkout experience included with the Print SDK (i.e. [Managed Checkout](../README.md#managed-checkout)) then you need to explicitly take payment from your users for the order to be printed and posted. You can create your own UI for capturing card details or you can use the [PayPal iOS SDK](https://github.com/paypal/PayPal-iOS-SDK).

Payments should be made directly to Kite's PayPal account rather than your own. We then pay you based on your desired margins that you have configured in the [developer dashboard](https://www.kite.ly). This is the recommended client side approach if you want to avoid paying for your own server(s) to validate customer payments.

Alternatively we do support a server side payment flow where the user pays you directly. In this approach you'll need a server to validate payment and issue a print request using our REST API. The client iOS app deals solely with your server to submit the print order. If your server is happy with the proof of payment it submits the order to our server on behalf of the client app. See [payment workflows](https://www.kite.ly/docs/1.1/payment_workflows) for more details regarding this approach.

_If you haven't already, see the [README](../README.md) for an initial overview and instructions for adding the SDK to your project._

Prerequisites
--------
1. [Create a print order](create_print_order.md) representing the product(s) you wish to have printed and posted
2. [Set the shipping address](shipping.md) to which the order will be delivered

Overview
--------
1. Take payment from the user
    - Using the [PayPal iOS SDK](https://github.com/paypal/PayPal-iOS-SDK) payment flow if you don't want to create your own UI
    - Alternatively create your own UI and use `OLPayPalCard` to process the payment
2. Attach the proof of payment to the `OLPrintOrder` to be verified server side
3. Submit the `OLPrintOrder` to our server for printing and posting

Sample Code
-----------

1. Take payment from the user. There are two approaches available if you don't want to run your own servers
    - Using the [PayPal iOS SDK](https://github.com/paypal/PayPal-iOS-SDK) payment flow if you don't want to create your own UI. Follow the best practices laid out in the PayPal iOS SDK [documentation](https://github.com/paypal/PayPal-iOS-SDK) for making a payment. 
    
	    You'll need to *use our PayPal Client Id & Receiver Email* in your transactions or the proof of payment you receive from PayPal will be rejected when you submit the print order to our servers. Depending on whether your using the Live or Sandbox printing environment the Client Id & Receiver Email values are different. 
	
	    The Sandbox print environment (`kOLPSPrintSDKEnvironmentSandbox`) validates order proof of payments against the Sandbox PayPal environment. The Live print environment (`kOLPSPrintSDKEnvironmentLive`) validates order proof of payments against the Live PayPal Environment.
	    
	    `[OLPSPrintSDK paypalClientId]` & `[OLPSPrintSDK paypalReceiverEmail]` will always return the correct PayPal values for the environment you supplied to `OLPSPrintSDK setAPIKey:withEnvironment:`.
	
	        ```obj-c
	        NSString *paypalClientId = [OLPSPrintSDK paypalClientId];
	        NSString *paypalReceiverEmail = [OLPSPrintSDK paypalReceiverEmail];
	        ```

    - Capture the users card details with your own UI and use `OLPayPalCard` to process the payment
    
        ```obj-c
        OLPayPalCard *card = [[OLPayPalCard alloc] init];
        card.type = kOLPayPalCardTypeVisa;
        card.number = @"4121212121212127";
        card.expireMonth = 12;
        card.expireYear = 2020;
        card.cvv2 = @"123";
        
        [card chargeCard:printOrder.cost currencyCode:printOrder.currencyCode description:@"A print order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
        // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
    }];
        ```
2. Attach the proof of payment to the `OLPrintOrder` to be verified server side

    ```obj-c
    OLPrintOrder *order = ...;
    order.proofOfPayment = proofOfPayment;
    ```
3. Submit the `OLPrintOrder` to our server for printing and posting. 

     ```obj-c
    [self.printOrder submitForPrintingWithProgressHandler:^(NSUInteger totalAssetsUploaded, NSUInteger totalAssetsToUpload, long long totalAssetBytesWritten, long long totalAssetBytesExpectedToWrite, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        // Show upload progress spinner, etc.
    } completionHandler:^(NSString *orderIdReceipt, NSError *error) {
       // If there is no error then you can display a success outcome to the user
    }];
    ```

Next Steps
----------

- [Register your payment details](https://www.kite.ly/accounts/billing/) with us so that we can pay you when your users place orders