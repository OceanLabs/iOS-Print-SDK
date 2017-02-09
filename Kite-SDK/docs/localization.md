Localization
==============

We currently offer support for localized strings in the following languages:
 - English (en)
 - French (fr)
 - Spanish (es)

 To use the above languages or a subset of them, you need to add an entry to your application's plist, CFBundleLocalizations, with the list of languages you require.


Example:
 ```
 <key>CFBundleLocalizations</key>
 	<array>
 		<string>en</string>
 		<string>fr</string>
 		<string>es</string>
 	</array>
 ```
