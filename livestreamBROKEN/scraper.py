import time
import urllib.request
import os.path
from os import path
import shutil

lastCheckTime = -1
CHECK_WAIT_TIME = 60
now = 0
countryData = {}


class CountryDatum:
    def __init__(self, ts, c, d, r):
        self.timestamp = ts
        self.caseCount = c
        self.deathCount = d
        self.recoveryCount = r


class Country:
    def __init__(self, n):
        self.name = n
        self.data = []

    def isThisNewData(self, newDatum):
        if len(self.data) == 0:
            return True
        else:
            myLatestDatum = self.data[-1]
            caseSame = (newDatum.caseCount == myLatestDatum.caseCount)
            deathSame = (newDatum.deathCount == myLatestDatum.deathCount)
            recoverySame = (newDatum.recoveryCount == myLatestDatum.recoveryCount)
            if caseSame and deathSame and recoverySame:
                return False
            else:
                return True


def addDatumToDatabase(timestamp, countryName, caseCount, deathCount, recoveryCount):
    recordingString = str(timestamp) + ",datum," + countryName + "," + str(caseCount) + "," + str(
        deathCount) + "," + str(recoveryCount) + "\n"
    thisDatum = CountryDatum(timestamp, caseCount, deathCount, recoveryCount)
    if countryName in countryData:
        thisCountry = countryData[countryName]
        if thisCountry.isThisNewData(thisDatum):
            thisCountry.data.append(thisDatum)
            return recordingString
    else:
        newCountry = Country(countryName)
        newCountry.data.append(thisDatum)
        countryData[countryName] = newCountry
        return recordingString
    return ""


def readLocalData():
    global lastCheckTime
    f = open('data.txt', 'r+')
    dataStrings = f.read().split("\n")
    f.close()

    lastLine = dataStrings[-2]
    parts = lastLine.split(",")
    lastCheckTime = int(parts[0])

    for i in range(len(dataStrings)):
        line = dataStrings[i]
        if len(line) >= 1:
            parts = line.split(",")
            if parts[1] == "datum":
                timestamp = int(parts[0])
                countryName = parts[2]
                caseCount = int(parts[3])
                deathCount = int(parts[4])
                recoveryCount = int(parts[5])
                addDatumToDatabase(timestamp, countryName, caseCount, deathCount, recoveryCount)


def getNumFromNastyHTML(s):
    str = s[s.index(">") + 1:].replace(",", "").replace(" ", "")
    if str == ' ' or str == '':
        return 0
    else:
        return int(str)


def doCheck():
    print("Checking for data at timestamp " + str(now))
    global lastCheckTime
    f = open('data.txt', 'a+')
    fs = open('dataStream.txt', 'a+')
    try:
        fs.write(str(now) + ",check\n")
        fp = urllib.request.urlopen("https://www.worldometers.info/coronavirus/")
        mybytes = fp.read()

        mystr = mybytes.decode("utf8")
        fp.close()

        tableStartIndex = mystr.index("table id=\"main_table_countries_today\" ")
        tableEndIndex = mystr.index("Total:", tableStartIndex)
        dataChunk = mystr[tableStartIndex:tableEndIndex]
        perCountryData = dataChunk.split("tr style")
        # print("OMOSHIROI "+str(len(dataChunk)))
        for i in range(1, len(perCountryData)):
            tableRow = perCountryData[i]
            cells = tableRow.split("</td>")
            countryName = ""
            firstCell = cells[0]
            if "Diamond Princess" in firstCell:
                countryName = "Diamond Princess"
            elif "</a>" in firstCell:
                endOfCountryName = firstCell.rfind("<")
                startOfCountryName = firstCell[0:endOfCountryName].rfind(">") + 1
                countryName = firstCell[startOfCountryName:endOfCountryName]
                # print(firstCell[0:200])
            else:
                startOfCountryName = firstCell.rfind(">") + 1
                countryName = firstCell[startOfCountryName:]
            while countryName[0] == " ":
                countryName = countryName[1:]
            while countryName[-1] == " ":
                countryName = countryName[:-1]

            # for ze in range(1,6):
            #    print(str(ze)+":   "+cells[ze])

            caseCount = getNumFromNastyHTML(cells[1])
            deathCount = getNumFromNastyHTML(cells[3])
            recoveryCount = getNumFromNastyHTML(cells[5])

            outputText = addDatumToDatabase(now, countryName, caseCount, deathCount, recoveryCount)
            f.write(outputText)
            fs.write(outputText)

        f.flush()
        f.close()
        fs.flush()
        fs.close()

        dayStamp = now // 86400
        backupFilepath = "backups/dataBackup" + str(dayStamp) + ".txt"
        if not path.exists(backupFilepath):
            shutil.copyfile('data.txt', backupFilepath)
    except Exception as e:
        fs.write(str(now) + ",exception occured: " + str(e) + "\n")

    lastCheckTime = now
    print("Done checking.")


readLocalData()

running = True
while running:
    now = int(time.time())
    if now - lastCheckTime >= CHECK_WAIT_TIME:
        doCheck()
    time.sleep(CHECK_WAIT_TIME)
