import time
from datetime import datetime
import numpy as np

START_DAY = 18262  # Jan 1, 2020
DAY_LEN = 538  # Days until Jun 21, 2021
PROCESSING_US_STATE_DATA = False

MILLION = 1000000
MAIN_PREFIX = "usState" if PROCESSING_US_STATE_DATA else "country"


def UNIX_TO_DATENUMSTR(n):
    return datetime.utcfromtimestamp((n + START_DAY) * 86400).strftime('%Y-%m-%d')


def dateStringToUnixDay(stri):
    striEdited = stri.replace(";", ",").replace("\"", "");
    result = time.mktime(datetime.strptime(striEdited, "%b %d, %Y").timetuple())
    return round(result / 86400) - START_DAY


def DAStoDA(str):
    s = str.index("[") + 1
    e = str.index("]")
    substr = str[s:e]
    return substr.split(",")


def strToInt(str):
    if str == "null":
        return -1
    else:
        return int(str)


def getStr(tag, name):
    array_D = None
    array_1 = None
    array_7 = None

    deather = -1
    for i in range(len(htmlLines)):
        htmlLine = htmlLines[i].replace(", 202",
                                        "; 202")  # Super shady hack to avoid strings like "Feb 15, 2020" having their commas be interpreted as delimiters for array values.
        if tag in htmlLine:
            deather = 0
        if deather >= 0 and deather <= 3:
            if htmlLine.count(",") >= 10:
                if deather == 0:
                    array_D = DAStoDA(htmlLine)
                elif deather == 1:
                    array_1 = DAStoDA(htmlLine)
                elif deather == 3:
                    array_7 = DAStoDA(htmlLine)
                deather += 1

    data_1 = np.zeros(DAY_LEN)
    data_7 = np.zeros(DAY_LEN)
    data_1.fill(-1)
    data_7.fill(-1)

    if array_D != None:
        for i in range(len(array_D)):
            day = dateStringToUnixDay(array_D[i])
            data_1[day] = strToInt(array_1[i])
            data_7[day] = strToInt(array_7[i])

    myStr = ""
    for day in range(DAY_LEN):
        myStr += str(int(data_1[day]))
        if day != DAY_LEN - 1:
            myStr += ","
    myStr += "\t"
    for day in range(DAY_LEN):
        myStr += str(int(data_7[day]))
        if day != DAY_LEN - 1:
            myStr += ","
    return myStr


f = open(MAIN_PREFIX + "List.tsv", "r+")
lines = f.read().split("\n")
f.close()

output = open(MAIN_PREFIX + "Data/" + "fullData_" + MAIN_PREFIX + "_" + UNIX_TO_DATENUMSTR(DAY_LEN - 1) + ".tsv", "w+")

counter = 0
for line in lines:
    if len(line) >= 2:
        parts = line.split("\t")
        name = parts[0]
        pop = int(parts[1])

        f = open(MAIN_PREFIX + "Data/" + name + ".html", "r+", encoding="utf-8")

        htmlLines = f.read().split("\n")
        f.close()

        cases_str = getStr("Daily New Cases in", name)
        death_str = getStr("Daily New Deaths in", name)

        output.write(name + "\t" + str(pop) + "\t" + cases_str + "\t" + death_str + "\n")
        counter += 1
        print("Done processing " + name + "! (" + str(counter) + "/" + str(len(lines)) + ")")

output.flush()
output.close()
