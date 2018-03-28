Order History
==============

Kite SDK keeps a history of all successful and failed orders. This is stored locally in the app on the user's device. You can access it by importing:
```obj-c
#import "OLPrintOrder+History.h"
```
Then get the array of OLPrintOrder objects with:
```obj-c
NSArray<OLPrintOrder *> orders = [OLPrintOrder printOrderHistory];
```

You can read a OLPrintOrder object's `printed` property to see if the submission was successful.

You can also create a OLReceiptViewController with `initWithPrintOrder:` to show the user the receipt of their order. If the order was unsuccessful they can retry from that screen.


For your convenience we also offer a basic View Controller that offers this functionality:
```
[self presentViewController:[OLKiteViewController orderHistoryViewController] animated:YES completion:NULL];
```
