Localization
==============

We currently offer support for localized strings in the following languages:
- English (en)
- French (fr)
- German (de)
- Italian (it)
- Spanish (es)
- Czech (cs)
- Danish (da)
- Finnish (fi)
- Hungarian (hu)
- Norwegian. (nb)
- Polish (pl)
- Portuguese (pt)
- Slovak (sk)
- Swedish (sv)

 To use the above languages or a subset of them, you need to add an entry to your application's plist, CFBundleLocalizations, with the list of languages you require.


Example:
 ```
 <key>CFBundleLocalizations</key>
 <array>
   <string>en</string>
   <string>fr</string>
   <string>es</string>
   <string>de</string>
   <string>it</string>
 </array>
 ```
