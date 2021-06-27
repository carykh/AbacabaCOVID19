f = open("blah.txt", "r+")
lines = f.read().split("\n")
f.close()

countryList = {}

signal = "href=\"/world-population/"
for line in lines:
    if signal in line:
        startIndex = line.index(signal) + len(signal)
        endIndex = line.index("-population", startIndex)
        country = line[startIndex:endIndex]
        if country not in countryList:
            popsIndex = line.index(">", endIndex) + 1
            popeIndex = line.index("<", popsIndex)
            pop = line[popsIndex:popeIndex].replace(",", "")
            countryList[country] = pop

f = open("countryList.tsv", "w+")
for key, value in countryList.items():
    f.write(key + "\t" + value + "\n")
f.flush()
f.close()
