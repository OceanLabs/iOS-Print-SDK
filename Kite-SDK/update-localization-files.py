import sys
import io
import csv

file = open(sys.argv[1], 'r')
untranslated = open(sys.argv[3], 'w')
untranslatedWriter = csv.writer(untranslated, delimiter=',', quotechar='"')
untranslatedWriter.writerow(["ENGLISH/INTERNAL","TO TRANSLATE","COMMENT/CONTEXT"])

result = open(sys.argv[4], 'w')

comment = ""

for line in file:
    if line[0] == """/""":
        if "No comment provided by engineer." in line:
            comment = ""
            continue
        comment = line
        continue
    elif (len(line) < 2):
        continue

    strings = line.split(" = ")
    if len(strings) < 2:
        continue        
        
    found = False
    
    translated = open(sys.argv[2], 'r')
    translatedReader = csv.reader(translated, delimiter=',', quotechar='"')
    next(translatedReader, '')
    for translatedLine in translatedReader:
        if len(translatedLine) == 0:
            continue
        
        if (strings[0])[1:-1] == translatedLine[0]:
            found = True
            result.write('"' + translatedLine[0] + "\" = \"" + translatedLine[1] + "\";\n")
            break

    translated.close()

    if found == False:
        secondary = open(sys.argv[5], 'r')
        secondaryReader = csv.reader(secondary, delimiter=',', quotechar='"')
        next(secondaryReader, '')
        for secondaryLine in secondaryReader:
            if (strings[0])[1:-1] == secondaryLine[0]:
                found = True
                result.write('"' + secondaryLine[0] + "\" = \"" + secondaryLine[1] + "\";\n")
                break
        secondary.close()

    if found == False:
        untranslatedWriter.writerow([strings[0][1:-1],strings[1][1:-3], comment[0:-1]])
        result.write('"' + strings[0][1:-1] + "\" = \"" + strings[1][1:-3] + "\";\n")
    
        
untranslated.close()
file.close()
result.close()
