import sys
import io
import csv

file = open(sys.argv[1], 'r')
untranslated = open(sys.argv[3], 'w')
untranslatedWriter = csv.writer(untranslated, delimiter=',', quotechar='"')

result = open(sys.argv[4], 'w')


for line in file:
    if (len(line) < 2 or line[0] == """/"""):
        continue
    strings = line.split(" = ")
    if len(strings) < 2:
        continue        
        
    found = False
    
    translated = open(sys.argv[2], 'r')
    translatedReader = csv.reader(translated, delimiter=',', quotechar='"')
    for translatedLine in translatedReader:
        if len(translatedLine) < 2:
            continue
           
        if (strings[0])[1:-1] == translatedLine[0]:
            found = True
            result.write('"' + translatedLine[0] + "\" = \"" + translatedLine[1] + "\";\n")
            break

    if found == False:
        untranslatedWriter.writerow([strings[0][1:-1],strings[1][1:-3]])
    
    translated.close()
        
untranslated.close()
file.close()
result.close()
