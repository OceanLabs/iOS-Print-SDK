Submitting a Print Order with Managed Checkout
==============

The Print SDK includes a robust checkout and payment experience that's proven to convert well with users. It can take care of the entire checkout process for you, no need to spend time building any user interfaces. 

This is the quickest approach to integration and perfect if you don't want to spend any time building a custom checkout experience.

If you don't want to use or customize the provided experience you can [build your own custom checkout UI](../README.md#).

_If you haven't already, see the [README](../README.md#Custom-Checkout) for an initial overview and instructions for adding the SDK to your project._


Overview
--------
1. Create a `OLPrintOrder` containing details of the product(s) you want to print
2. Create and present a `OLCheckoutViewController` passing it the `OLPrintOrder` object you created in Step 1

Sample Code
-----------
1. See [Creating a Print Order](create_print_order.md) for details on creating the `OLPrintOrder`
2. Create and present a `OLCheckoutViewController` passing it the `OLPrintOrder` object you created in Step 1

     ```obj-c
    // SomeViewController.m
    #import "OLPSPrintSDK.h"

    @implementation SomeViewController

    - (void)submitPrintOrder:(OLPrintOrder *)printOrder {
        OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    @end
    ```
*Note: If you prefer you can also present the `OLCheckoutViewController` as a modal view controller rather than pushing it onto the navigation stack.*

Next Steps
----------

- That's all there is to it from an integration perspective! Submitted print orders will appear in the [developer dashboard](https://www.kite.ly/). You'll also need to register your payment details with us in the dashboard so that we can pay you when your users place orders.
- Alternatively you can [build your own custom checkout UI](../README.md#) for complete control of the checkout and payment process.