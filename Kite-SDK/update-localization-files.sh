command -v iconv >/dev/null 2>&1 || { exit 0; }

cd PSPrintSDK/OLKiteLocalizationResources.bundle/

find ../ -name \*.m | xargs genstrings -o .
rm Localizable.strings

filename="KitePrintSDK.strings"
translated="KitePrintSDK.translated.csv"
converted="KitePrintSDK.converted.strings"
untranslated="KitePrintSDK.untranslated.csv"
result="KitePrintSDK.result.strings"
secondary="KitePrintSDK.secondary.csv"

iconv -f UTF-16 -t UTF-8 $filename > $converted
if [ ! -f $converted ]; then
cp $filename $converted
fi

sed -i -e 's/\%1\$/\%/g' $converted
sed -i -e 's/\%2\$/\%/g' $converted
sed -i -e 's/\%3\$/\%/g' $converted

rm $filename

for lang in `find . -name \*.lproj`; do

cd $lang
pwd

touch $untranslated
touch $result
touch $translated
touch $secondary

python ../../../update-localization-files.py "`pwd`/../$converted" "`pwd`/$translated" "`pwd`/$untranslated" "`pwd`/$result" "`pwd`/$secondary"

mv $result $filename

cd ..

done

rm $converted
rm $converted-e