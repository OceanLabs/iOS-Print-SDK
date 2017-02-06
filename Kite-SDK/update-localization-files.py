import sys
import io

file = open(sys.argv[1], 'r')
untranslated = open(sys.argv[3], 'w')
result = open(sys.argv[4], 'w')

for line in file:
    if (len(line) < 2 or line[0] == """/"""):
        continue
    strings = line.split(" = ")
    if len(strings) < 2:
        continue        
        
    found = False
    
    translated = open(sys.argv[2], 'r')
    for translatedLine in translated:
        if (len(translatedLine) < 2 or translatedLine[0] == """/"""):
            continue
        translatedStrings = translatedLine.split(" = ")
        if len(translatedStrings) < 2:
            continue
            
        if strings[0] == translatedStrings[0]:
            found = True
            result.write(translatedLine)
            break

    if found == False:
        untranslated.write(line)
    
    translated.close()
        
file.close()
result.close()
untranslated.close()
