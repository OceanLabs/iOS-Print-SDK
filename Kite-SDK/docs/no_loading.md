Eliminating Loading
==============

You can create a OLKiteViewController like usual and call `startLoadingWithCompletionHandler:` on it make it load everything it needs from the network in the background. You can show it immediately or keep it in memory to show it later. 

If you let the OLKiteViewController object be destroyed, you can create a new one and set its `preserveExistingTemplates` property to true, which will allow it to load immediately, even without calling `startLoadingWithCompletionHandler:`. This is achieved by the first object caching the data it received from the network.

Note: This is not needed when launching directly to checkout.


