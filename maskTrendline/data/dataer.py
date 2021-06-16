import numpy as np
import time
import datetime
import unidecode
import scipy.stats

MILLION = 1000000
START_DAY = 18262
DAY_LEN = 366+8
WEEK_HALF = 7
def dateStringToDays(stri):
    unixSeconds = time.mktime(datetime.datetime.strptime(stri, "%Y-%m-%d").timetuple())
    days = round(unixSeconds/86400)-18262
    return days
    
def trimExtra(stri):
    endings = [" City and Borough", " Borough", " Census Area"," County", " Municipality"," Parish"]
    
    stri = unidecode.unidecode(stri)
    for ending in endings:
        if(stri[len(stri)-len(ending):] == ending):
            stri = stri[:len(stri)-len(ending)]
    if stri[0] == ".":
        stri = stri[1:]
    return stri
    
def WAindex(arr,day,WINDOW_WIDTH):
    minI = max(0,day-WINDOW_WIDTH)
    maxI = min(len(arr)-1,day+WINDOW_WIDTH)
    counter = 0
    summer = 0
    for d in range(minI,maxI+1):
        value = max(0,arr[d]-arr[max(0,d-1)])
        weight = 1-(abs(d-day)/WINDOW_WIDTH)
        
        counter += weight
        summer += weight*value
    
    return summer/counter
    
def sqlFix(stri):
    stri = trimExtra(stri.replace(" city"," City"))
    changes = [["New York City","New York"],
    ["Kansas City","Jackson"],["Joplin","Jasper"]]
    for change in changes:
        if stri == change[0]:
            return change[1]
    return stri

def newJerseyFix(arr):
    anomalousGrowth = arr[369]-arr[368]
    typicalGrowth = arr[368]-arr[367]
    decreaseFix = anomalousGrowth-typicalGrowth
    arr[369:] -= decreaseFix

def rhodeIslandFix(arr):
    lastIncreasingDay = 120
    for d in range(120,DAY_LEN):
        increase = arr[d]-arr[d-1]
        if increase >= 1:
            if d >= lastIncreasingDay+2: # multi-day delay detected!
                startVal = arr[lastIncreasingDay]
                endVal = arr[d]
                for d2 in range(lastIncreasingDay,d):
                    prog = (d2-lastIncreasingDay)/(d-lastIncreasingDay)
                    arr[d2] = int(startVal+(endVal-startVal)*prog)
            lastIncreasingDay = d

stateName_to_stateCode = {}
stateCode_to_stateName = {}
statePopulations = {}
stateCases = {}
stateCasesSmoothed = {}
stateMaskPops = {}

countyPopulations = {}
countyCases = {}
countyCasesSmoothed = {}

f = open("stateCodes.tsv", "r+", encoding="utf-8")
lines = f.read().split("\n")
f.close()
for line in lines:
    parts = line.split("\t")
    stateName = parts[0]
    stateCode = parts[1]
    stateName_to_stateCode[stateName] = stateCode
    stateCode_to_stateName[stateCode] = stateName
    statePopulations[stateCode] = 0
    stateCases[stateCode] = np.zeros((DAY_LEN),dtype=int)
    stateCasesSmoothed[stateCode] = np.zeros((DAY_LEN))
    stateMaskPops[stateCode] = 0

f = open("countyPopulations.tsv", "r+", encoding="utf-8")
lines = f.read().split("\n")
f.close()
for i in range(5,len(lines)-6):
    line = lines[i]
    parts = line.split("\t")
    countyString = parts[0]
    countyParts = countyString.split(",")
    
    countyName = trimExtra(countyParts[0])
    stateName = countyParts[1][1:]
    stateCode = stateName_to_stateCode[stateName]
    population = int(parts[-1].replace(",",""))
    
    key = countyName+","+stateCode
    countyPopulations[key] = population
    countyCases[key] = np.zeros((DAY_LEN),dtype=int)
    countyCasesSmoothed[key] = np.zeros((DAY_LEN))
     
    statePopulations[stateCode] += population
    
    
fips_to_countyName = {}
f = open("fips.tsv", "r+", encoding="utf-8")
lines = f.read().split("\n")
f.close()
for i in range(2,len(lines)-1):
    line = lines[i]
    parts = line.split("\t")
    fips = parts[0]
    countyName = trimExtra(parts[1])+","+parts[2]
    fips_to_countyName[fips] = countyName

countyName_to_maskUsage = {}
f = open("mask.csv", "r+", encoding="utf-8")
lines = f.read().split("\n")
f.close()
for i in range(1,len(lines)-1):
    line = lines[i]
    parts = line.split(",")
    maskUsage = float(parts[4])+float(parts[5])
    fips = parts[0]
    key = fips_to_countyName[fips]
    countyName_to_maskUsage[key] = maskUsage
    
    stateCode = key[-2:]
    stateMaskPops[stateCode] += maskUsage*countyPopulations[key]

# us-countries.sql is a large file that includes COVID-19 case and death counts 
# for every county in the US per day. It's 36 MB, and it changes every day, so I didn't want to
# include it in my GitHub repo. Here's the source:
# https://github.com/nytimes/covid-19-data


unknownCount = 0
with open("us-counties.sql", encoding="utf-8") as infile:
    i = 0
    for line in infile:
        if i >= 1:
            parts = line.split(",")
            days = dateStringToDays(parts[0])
            caseCount = int(parts[4])
            
            stateCode = stateName_to_stateCode[parts[2]]
            stateCases[stateCode][days] += caseCount
            if parts[1] == "Unknown":
                unknownCount += 1
            else:
                countyName = sqlFix(parts[1])
                key = countyName+","+stateCode
                countyCases[key][days] = caseCount
            
            
            
        i += 1
        if i%10000 == 0:
            print("Done READING line "+str(i)+" of 910783")
print("unknowns: "+str(unknownCount))


newJerseyFix(stateCases["NJ"])
rhodeIslandFix(stateCases["RI"])
for countyName in countyPopulations: 
    if ",NJ" in countyName: # Smooth out super large 2020-Jan-04 New Jersey anomaly
        newJerseyFix(countyCases[countyName])
    if ",RI" in countyName: # Smooth out Rhode Island case reporting delays (days with supposedly "0" cases)
        rhodeIslandFix(countyCases[countyName])

f = open("covid19_12_county_data.csv", "w+", encoding="utf-8")
counting = 0
for countyName in countyPopulations:
    pop = countyPopulations[countyName]
    if countyName in countyName_to_maskUsage:
        mask = countyName_to_maskUsage[countyName]
        stri = countyName.replace(",",";")+","+str(pop)+","+('%.3f'%mask)
        for d in range(DAY_LEN):
            countyCasesSmoothed[countyName][d] = WAindex(countyCases[countyName],d,WEEK_HALF)/pop*MILLION
            stri += ","+('%.3f'%countyCasesSmoothed[countyName][d])
        f.write(stri+"\n")
    else:
        print("NOTE: "+countyName+" does not have mask data.")
    counting += 1
    if counting%100 == 0:
        print("Done WRITING county file #"+str(counting)+" of "+str(len(countyPopulations)))
f.flush()
f.close()

f = open("covid19_12_county_trendline.csv", "w+", encoding="utf-8")
for day in range(DAY_LEN):
    reg_x = np.zeros(len(countyPopulations))
    reg_y = np.zeros(len(countyPopulations))
    counting = 0
    for countyName in countyPopulations:
        if countyName in countyName_to_maskUsage:
            pop = countyPopulations[countyName]
            reg_x[counting] = countyName_to_maskUsage[countyName]
            reg_y[counting] = countyCasesSmoothed[countyName][day]
            counting += 1
    reg_x = reg_x[:counting]
    reg_y = reg_y[:counting]
    slope, intercept, r_value, p_value, std_err = scipy.stats.linregress(reg_x, reg_y)
    f.write(str(slope)+","+str(intercept)+","+str(r_value)+","+str(p_value)+","+str(std_err)+"\n")
f.flush()
f.close()
print("Done with county file. Starting state file!")
    
    
    
    
    
f = open("covid19_12_state_data.csv", "w+", encoding="utf-8")
counting = 0
for stateCode in statePopulations:
    pop = statePopulations[stateCode]
    mask = stateMaskPops[stateCode]/statePopulations[stateCode]
    stri = stateCode+","+str(pop)+","+('%.3f'%mask)
    for d in range(DAY_LEN):
        stateCasesSmoothed[stateCode][d] = WAindex(stateCases[stateCode],d,WEEK_HALF)/pop*MILLION
        stri += ","+('%.3f'%stateCasesSmoothed[stateCode][d])
    f.write(stri+"\n")
f.flush()
f.close()

f = open("covid19_12_state_trendline.csv", "w+", encoding="utf-8")
for day in range(DAY_LEN):
    reg_x = np.zeros(len(countyPopulations))
    reg_y = np.zeros(len(countyPopulations))
    counting = 0
    for stateCode in statePopulations:
        pop = statePopulations[stateCode]
        mask = stateMaskPops[stateCode]/pop
        if mask >= 0.001: #There are data points
            reg_x[counting] = mask
            reg_y[counting] = stateCasesSmoothed[stateCode][day]
            counting += 1
    reg_x = reg_x[:counting]
    reg_y = reg_y[:counting]
    slope, intercept, r_value, p_value, std_err = scipy.stats.linregress(reg_x, reg_y)
    f.write(str(slope)+","+str(intercept)+","+str(r_value)+","+str(p_value)+","+str(std_err)+"\n")
f.flush()
f.close()
    
print("DONE WITH EVERYTHING.")
    
    