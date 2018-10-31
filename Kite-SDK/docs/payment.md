Paying for and Submitting a Print Order
==============

If you don't want to use the print shop experience included with the Print SDK (i.e. the [Kite Print Shop Experience](print_shop.md)) you can create your own experience but for checking out you *must* use the Checkout APIs of this SDK. If you need to have your own checkout experience as well then you must use Kite's REST APIs.

Payments should be made directly to Kite's PayPal account rather than your own. We then pay you based on your desired margins that you have configured in the [developer dashboard](https://www.kite.ly). This is the recommended client side approach if you want to avoid paying for your own server(s) to validate customer payments.

Alternatively we do support a server side payment flow where the user pays you directly. In this approach you'll need a server to validate payment and issue a print request using our REST API. The client iOS app deals solely with your server to submit the print order. If your server is happy with the proof of payment it submits the order to our server on behalf of the client app. See [payment workflows](https://www.kite.ly/docs/#payment-workflows) for more details regarding this approach.

_If you haven't already, see the [README](../../README.md) for an initial overview and instructions for adding the SDK to your project._

Next Steps
----------

- [Register your payment details](https://www.kite.ly/settings/billing/) with us so that we can pay you when your users place orders
