import numpy as np

YEAR_COUNT = 8
DAYS_PER_WEEK = 7


def removeInnerCommas(s):
    while "\"" in s:
        firstIndex = s.index("\"")
        secondIndex = s.index("\"", firstIndex + 1)
        middleChunk = s[firstIndex + 1:secondIndex].replace(",", "")
        s = s[:firstIndex] + middleChunk + s[secondIndex + 1:]
    return s.replace("\"", "")


def printOff(y, offset):
    cum = 0
    for w in range(53):
        for diw in range(DAYS_PER_WEEK):
            if diw == 3:
                cum += weeklyData[y + offset, w] / DAYS_PER_WEEK
            elif diw < 3:
                prev = weeklyData[y + offset, max(0, w - 1)]
                curr = weeklyData[y + offset, w]
                here = prev + (curr - prev) * (diw + 4) / 7
                cum += here / DAYS_PER_WEEK
            else:
                curr = weeklyData[y + offset, w]
                next = weeklyData[y + offset, min(52, w + 1)]
                here = curr + (next - curr) * (diw - 3) / 7
                cum += here / DAYS_PER_WEEK
            f.write(str(int(round(cum))) + ",")


f = open("National_Custom_Data_2013-2021.csv", "r+")
lines = f.read().split("\n")
f.close()
weeklyData = np.zeros((16, 53))

f = open("fluTotals.txt")
fluLines = f.read().split("\n")
f.close()

for i in range(1, len(lines) - 1):
    line = removeInnerCommas(lines[i])
    parts = line.split(",")
    year = int(parts[3][5:7]) - 14
    preWeek = int(parts[4])
    if preWeek <= 39:
        week = preWeek + 12
        if year == 1:
            week = preWeek + 13
    else:
        week = preWeek - 40
    value = int(parts[9])
    weeklyData[year][week] = value
    weeklyData[year + 7][week] = value

f = open("daily_flu_deaths_2021-06-24.tsv", "w+")

for y in range(YEAR_COUNT):
    fineDataSum = np.sum(weeklyData[y])
    coarseDataSum = int(fluLines[y])
    weeklyData[y] *= coarseDataSum / fineDataSum
    print(str(y) + ":   " + str(coarseDataSum / fineDataSum))
    yr = y + 13
    f.write("Flu season (20" + str(yr) + "-" + str(yr + 1) + "),est,")
    printOff(y, 0)
    f.write("\n")

    f.write("Flu season (20" + str(yr) + "-" + str(yr + 1) + "),inc,")
    printOff(y, 7)
    f.write("\n")
f.flush()
f.close()
