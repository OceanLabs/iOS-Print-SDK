Setting a Shipping Address
==============

If you don't want to use the checkout experience included with the Print SDK (i.e. the [Kite Print Shop Experience](print_shop.md)) then you need to explicitly set the shipping address for a print order. Typically you will create your own UI to capture shipping details from your users. 

The Print SDK also includes worldwide address search/lookup functionality that you can use to improve the user experience of your app.

_If you haven't already, see the [README](../README.md) for an initial overview and instructions for adding the SDK to your project._

Prerequisites
--------
1. [Create a print order](create_print_order.md) representing the product(s) you wish to have printed and posted

Overview
--------
1. Create a `OLAddress` containing details of the address that the print order will be shipped to. You have two options:
    - Create the `OLAddress` manually
    - Search/lookup the `OLAddress` using the SDK's worldwide address search and lookup functionality
2. Set the `OLPrintOrder` shipping address to the one you created in Step 1

Sample Code
-----------
1. You have two options when creating an `OLAddress`
    - Create the address manually

        ```obj-c
        OLAddress *a    = [[OLAddress alloc] init];
        a.recipientName = @"Deon Botha";
        a.line1         = @"27-28 Eastcastle House";
        a.line2         = @"Eastcastle Street";
        a.city          = @"London";
        a.stateOrCounty = @"London";
        a.zipOrPostcode = @"W1W 8DH";
        a.country       = [OLCountry countryForCode:@"GBR"];
        ```

    - Search for the address

        ```obj-c
        - (void)doAddressSearch {
            OLCountry *usa = [OLCountry countryForCode:@"USA"];
            [OLAddress searchForAddressWithCountry:usa query:@"1 Infinite Loop" delegate:self];
        }

        #pragma mark - OLAddressSearchRequestDelegate methods

        - (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithMultipleOptions:(NSArray *)options {
            // present choice of OLAddress' to the user
        }

        - (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithUniqueAddress:(OLAddress *)addr {
            // Search resulted in one unique address
        }

        - (void)addressSearchRequest:(OLAddressSearchRequest *)req didFailWithError:(NSError *)error {
            // Oops something went wrong
        }
        ```
2. Set the `OLPrintOrder` shipping address to the one you created in Step 1

    ```obj-c
    OLPrintOrder *order = ...;
    order.shippingAddress = address;
    ```

Next Steps
----------

- [Take payment from the user](payment.md) for the order and submit it to our servers for printing and posting
