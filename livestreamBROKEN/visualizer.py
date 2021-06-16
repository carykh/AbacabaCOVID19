import time
import urllib.request
import os.path
from os import path
import math
import numpy as np
import random
from datetime import datetime
import pygame

prevNowUR = time.time()
lastCheckTime = -1
lastRankCheckTime = -1
CHECK_WAIT_TIME = 30
RANK_CHECK_WAIT_TIME = 0.5
DAY_LEN = 86400
nowR = 0
nowUR = 0
countryData = {}
ranking = []
TOP_TO_SHOW = 10
TRANS_SPEED = 1.7
ARROW_PULSE_SPEED = 1000
BG_COLOR = (0,0,0)
minorCountryEvents = []
SWAP_COLOR = (255,236,39)

pygame.init()
pygame.display.set_mode()

fontTiny = pygame.font.SysFont("Jygguip 1", 18)
fontSmall = pygame.font.SysFont("Jygquip 1", 23)
font18 = pygame.font.SysFont("Jygquip 1", 19)
font36 = pygame.font.SysFont("Jygquip 1", 38)

expla = pygame.image.load("interpolation.png")
key = pygame.image.load("key.png")

playMusic = True

#c = pygame.mixer.Sound('C:/Users/caryk/Documents/Actual Sound Effects/alien_broadcast.mp3')

countSounds = [pygame.mixer.Sound('sounds/hurtLouder.wav'), pygame.mixer.Sound('sounds/bell_church_single.wav'), pygame.mixer.Sound('sounds/glitter_whoosh.wav')]
countSounds[0].set_volume(0.6)
countSounds[1].set_volume(0.3)
countSounds[2].set_volume(0.1)

class CountryDatum:
    def __init__(self,ts,ncounts):
        self.timestamp = ts
        self.counts = ncounts

    def equals(self,other):
        for ct in range(3):
            if self.counts[ct] != other.counts[ct]:
                return False
        return True

class Country:

    def __init__(self,n):
        self.name = n
        self.data = []
        self.currentDatumUnrounded = None
        self.currentDatumRounded = None
        self.currentCrossoverTime = -1
        self.prevDatum = None
        self.index = 0

        self.appData = None

        self.currentRank = -1
        self.visibleRank = -1
        self.progs = [0,0,0]
        self.slopes = [0,0,0]

        self.flag = None
        imageFilepath = "flags/flag-of-"+n.replace(" ","-")+".png"
        if path.exists(imageFilepath):
            flagImg = pygame.image.load(imageFilepath)
            self.flag = pygame.transform.scale(flagImg, (round(22/120*204), 22))

    def isThisNewData(self,newDatum):
        if len(self.data) == 0:
            return True
        else:
            myLatestDatum = self.data[-1]
            return (not myLatestDatum.equals(newDatum))

    def getTSIfromTimestamp(self,ts,start,end):
        if start > end:
            return start-1
        mid = (start+end)//2
        midVal = self.data[mid].timestamp
        #print("Checking with index "+str(mid)+", which has value "+str(midVal))
        if ts == midVal:
            return mid
        elif ts > midVal:
            return self.getTSIfromTimestamp(ts,mid+1,end)
        else:
            return self.getTSIfromTimestamp(ts,start,mid-1)

    def updateData(self,ts): # day-long slow drip
        TScount = len(self.data)

        TSI = self.getTSIfromTimestamp(ts,0,TScount-1)
        TSPI = self.getTSIfromTimestamp(ts-DAY_LEN,0,TScount-1)
        self.currentDatumUnrounded = CountryDatum(ts,[0,0,0])
        if TSPI >= 0:
            prevDatum = self.data[TSPI]
            for ct in range(3):
                self.currentDatumUnrounded.counts[ct] = prevDatum.counts[ct]

        self.activeSlope = 0
        for TSI_step in range(TSPI+1,TSI+1):
            prevDatum = self.data[TSI_step-1]
            stepDatum = self.data[TSI_step]
            deltas = [0,0,0]
            for ct in range(3):
                deltas[ct] = stepDatum.counts[ct]-prevDatum.counts[ct]
            prog = (ts-stepDatum.timestamp)/DAY_LEN
            prog = min(max(prog,0),1)
            for ct in range(3):
                self.currentDatumUnrounded.counts[ct] += deltas[ct]*prog
                self.slopes[ct] += deltas[ct]

        minTimeToNext = 2000000000
        minTimeFromLast = 2000000000
        self.currentDatumRounded = CountryDatum(ts,[0,0,0])
        for ct in range(3):
            self.progs[ct] = (self.currentDatumUnrounded.counts[ct]+0.5)%1.0
            self.currentDatumRounded.counts[ct] = round(self.currentDatumUnrounded.counts[ct])
            self.slopes[ct] /= DAY_LEN

            if self.slopes[ct] != 0:
                OFFSET = 0.3+0.0003*self.index
                timeToNext = (1-self.progs[ct])/self.slopes[ct]+OFFSET
                minTimeToNext = min(timeToNext,minTimeToNext)

                timeFromLast = self.progs[ct]/self.slopes[ct]+OFFSET
                minTimeFromLast = min(timeFromLast,minTimeFromLast)

        if self.appData != None and self.appData[3] >= TOP_TO_SHOW:
            self.IIMCE(minTimeToNext)
            self.IIMCE(-minTimeFromLast)

    def IIMCE(self,val):
        global minorCountryEvents
        if abs(val) < 1000000000:
            index = MCBS(minorCountryEvents,val,0,len(minorCountryEvents)-1)+1
            minorCountryEvents.insert(index,[self.name,val])


    def updateCrossoverPoint(self,other):
        myDS = self.currentDatumUnrounded
        otherDS = other.currentDatumUnrounded
        myStart = myDS.counts[0]-myDS.counts[1]-myDS.counts[2]
        otherStart = otherDS.counts[0]-otherDS.counts[1]-otherDS.counts[2]
        mySpeed = self.getCurrentActiveSlope() # in days
        otherSpeed = other.getCurrentActiveSlope() # in days
        gapCloseSpeed = mySpeed-otherSpeed
        if otherStart < myStart:
            return 0
        elif gapCloseSpeed <= 0:
            self.currentCrossoverTime = -1
        else:
            gap = otherStart-myStart
            daysToClose = gap/gapCloseSpeed # in days
            self.currentCrossoverTime = max(0,daysToClose)

    def getDatumSmoothAtTimeStampOldFashioned(self,ts): # connects the dots
        TScount = len(self.data)
        TSI = self.getTSIfromTimestamp(ts,0,TScount-1)

        if TSI == -1: # We're before the first timestemp
            return self.data[0]
        if TSI == TScount-1: # We're on the last timestamp
            return self.data[TScount-1]
        else:
            startDatum = self.data[TSI]
            endDatum = self.data[TSI+1]
            timeProg = (ts-startDatum.timestamp)/(endDatum.timestamp-startDatum.timestamp)

            progs = [0,0,0]
            for ct in range(3):
                progs[ct] = round(timeProg*(endDatum.counts[ct]-startDatum.counts[ct])+startDatum.counts[ct])
            return CountryDatum(timeProg,progs)

    def getCurrentActive(self):
        datum = self.currentDatumRounded
        return datum.counts[0]-datum.counts[1]-datum.counts[2]

    def getCurrentActiveSlope(self):
        return self.slopes[0]-self.slopes[1]-self.slopes[2]

    def initiateAppData(self,rank):
        c = self.currentDatumRounded.counts
        self.appData = [c[0]-c[1]-c[2],c[1],c[2],rank]

    def updateAppData(self, fac, i, isWorld):
        datum = self.currentDatumRounded
        active = self.getCurrentActive()

        prev = self.prevDatum
        if playMusic and isWorld and prev != None and not prev.equals(datum):
                for ct in range(3):
                    if datum.counts[ct] > prev.counts[ct]:
                        countSounds[ct].play()
        self.prevDatum = datum

        a = self.appData
        a[0] += (active-a[0])*fac
        a[1] += (datum.counts[1]-a[1])*fac
        a[2] += (datum.counts[2]-a[2])*fac
        a[3] += (i-a[3])*fac
        self.appData = a

    def getTiebreakers(self):
        counts = self.currentDatumRounded.counts
        return [self.getCurrentActive(), counts[0], counts[1]]



def initiateEverything():
    setNows()
    secondlyUpdate(nowR)
    for rank in range(len(ranking)):
        c = ranking[rank]
        countryData[c].initiateAppData(rank)
    world.initiateAppData(-1)

def setNows():
    global nowUR
    global nowR
    nowUR = time.time()
    nowR = int(nowUR)

def clearDataStream():
    f = open("dataStream.txt","w+")
    f.flush()
    f.close()

def addDatumToDatabase(timestamp,countryName,counts):
    recordingString = str(timestamp)+",datum,"+countryName+","+str(counts[0])+","+str(counts[1])+","+str(counts[2])+"\n"
    thisDatum = CountryDatum(timestamp,counts)
    if countryName in countryData:
        thisCountry = countryData[countryName]
        if thisCountry.isThisNewData(thisDatum):
            thisCountry.data.append(thisDatum)
            return recordingString
    else:
        newCountry = Country(countryName)
        newCountry.data.append(thisDatum)
        newCountry.index = len(countryData)
        countryData[countryName] = newCountry
        return recordingString
    return ""

def parseFile(fileName):
    global lastCheckTime
    f = open(fileName, 'r+')
    dataStrings = f.read().split("\n")
    f.close()
    lastCheckTime = nowR

    if len(dataStrings) <= 1:
        return

    lastLine = dataStrings[-2]
    parts = lastLine.split(",")
    for i in range(len(dataStrings)):
        line = dataStrings[i]
        if len(line) >= 1:
            parts = line.split(",")
            if parts[1] == "datum":
                timestamp = int(parts[0])
                countryName = parts[2]
                counts = [int(parts[3]),int(parts[4]),int(parts[5])]
                addDatumToDatabase(timestamp,countryName,counts)

def readLocalData():
    parseFile('data.txt')
    clearDataStream()

def getNumFromNastyHTML(s):
    str = s[s.index(">")+1:].replace(",","")
    if str == ' ' or str == '':
        return 0
    else:
        return int(str)

def checkDataStream():
    print("Checking for stream at timestamp "+str(nowR))
    parseFile('dataStream.txt')
    clearDataStream()
    print("Done checking.")



def secondlyUpdate(ts):
    global ranking
    global minorCountryEvents
    ranking = []
    minorCountryEvents = []
    totals = [0,0,0]
    for c in countryData:
        co = countryData[c]
        co.updateData(ts)
        insertionIndex = RBS(ranking,ts,co,0,len(ranking)-1)+1
        ranking.insert(insertionIndex,c)

        for ct in range(0,3):
            totals[ct] += co.currentDatumRounded.counts[ct]

    for i in range(len(ranking)):
        c = ranking[i]
        co = countryData[c]
        if i == 0:
            co.currentCrossoverTime = -1
        else:
            co.updateCrossoverPoint(countryData[ranking[i-1]])

    world.currentDatumRounded = CountryDatum(ts,totals)

def getRelation(a,b):
    leng = len(a)
    for i in range(leng):
        if a[i] < b[i]:
            return -1
        elif a[i] > b[i]:
            return 1
    return 0

def RBS(list,ts,co,start,end):
    if start > end:
        return start-1
    mid = (start+end)//2

    myVals = co.getTiebreakers()
    midVals = countryData[list[mid]].getTiebreakers()
    relation = getRelation(myVals,midVals)

    if relation == 0:
        return mid
    elif relation == -1:
        return RBS(list,ts,co,mid+1,end)
    else:
        return RBS(list,ts,co,start,mid-1)

def MCBS(list,val,start,end):
    if start > end:
        return start-1
    mid = (start+end)//2

    midVal = list[mid][1]

    if val == midVal:
        return mid
    elif val > midVal:
        return MCBS(list,val,mid+1,end)
    else:
        return MCBS(list,val,start,mid-1)

def getMinorView(frac):
    indexS = MCBS(minorCountryEvents,frac,0,len(minorCountryEvents)-1)
    indexE = indexS+1

    timeS = minorCountryEvents[indexS][1]
    timeE = minorCountryEvents[indexE][1]
    MVtimeFrac = (frac-timeS)/(timeE-timeS)

    coS = countryData[minorCountryEvents[indexS][0]]
    coE = countryData[minorCountryEvents[indexE][0]]
    rankS = coS.appData[3]
    rankE = coE.appData[3]

    desiredRank = cosInterExtreme(rankS,rankE,MVtimeFrac)
    return desiredRank

def timeStr(n):
    intN = int(n)
    sec1 = intN%10
    sec10 = (intN//10)%6
    min1 = (intN//60)%10
    min10 = (intN//600)%6
    hrs = intN//3600
    if intN == 0:
        return "any moment"
    elif hrs >= 24:
        return "a long time"
    elif hrs >= 1:
        return str(hrs)+":"+str(min10)+str(min1)+":"+str(sec10)+str(sec1)
    elif min10 >= 1:
        return str(min10)+str(min1)+":"+str(sec10)+str(sec1)
    else:
        return str(min1)+":"+str(sec10)+str(sec1)


def getXFromPos(p):
    x = 90-2-10*(p+1)
    if p >= 3:
        x -= 5
    return x

def digitLen(n):
    intN = int(n)
    if intN == 0:
        return 1
    leng = 0
    while intN >= 1:
        intN = intN//10
        leng += 1
    return leng

def digitAt(n, pos):
    intN = int(n)
    for i in range(pos):
        intN = intN//10
    return intN%10

def drawClock(statPanel,t_c,scale,co,timeFrac,ct):
    pygame.draw.ellipse(statPanel, t_c,(0.5*scale,0.5*scale,19*scale,19*scale),1*scale)
    f = co.progs[ct]+co.slopes[ct]*timeFrac
    end_pos = ((10+8.5*math.sin(f*2*math.pi))*scale, (10-8.5*math.cos(f*2*math.pi))*scale)
    pygame.draw.line(statPanel, t_c, (10*scale,10*scale), end_pos, 1*scale)

def rankify(n):
    ending = ""
    nHun = (int(n))%100
    if nHun >= 11 and nHun <= 20:
        ending = "th"
    elif nHun%10 == 1:
        ending = "st"
    elif nHun%10 == 2:
        ending = "nd"
    elif nHun%10 == 3:
        ending = "rd"
    else:
        ending = "th"
    return str(n)+ending

def lighten(col, fac):
    r = col[0]
    g = col[1]
    b = col[2]
    newR = r+(255-r)*fac
    newG = g+(255-g)*fac
    newB = b+(255-b)*fac
    return [newR, newG, newB]

def drawBoxFor(i,c,co,elapsed,LOC,timeFrac,isWorld):
    COLORS = [[154,79,80],[75,34,58],[90,200,245]]
    TCOLORS = [[255,255,255],[255,255,255],[0,0,0]]
    LOCS = [[3,24],[207,44],[207,24]]

    countryPanel = pygame.surface.Surface((450, 67))
    countryPanel.fill(BG_COLOR)

    pygame.draw.rect(countryPanel, (70,70,80), (0,0,300,67))

    rankDig = -3
    if not isWorld:
        rankDig = 1
        if i >= 99:
            rankDig = 3
        elif i >= 9:
            rankDig = 2

        rank_surf = fontSmall.render(rankify(i+1),1,(255,255,255))
        countryPanel.blit(rank_surf,(3,-1))
    txt_surf = fontSmall.render(c, 1, (255,255,255))
    if co.flag == None:
        countryPanel.blit(txt_surf,(37+10*rankDig,-1))
    else:
        countryPanel.blit(co.flag,(32+10*rankDig,2))
        countryPanel.blit(txt_surf,(39+10*rankDig+co.flag.get_size()[0],-1))

    waterMark_surf = fontTiny.render("A B A C A B A",1,(145,145,145))
    countryPanel.blit(waterMark_surf,(215,5))

    for ct in range(2,-1,-1):
        n = co.appData[ct]
        prog = n%1.0
        scale = 1
        fontC = font18
        if ct == 0:
            scale = 2
            fontC = font36
        statPanel = pygame.surface.Surface((90*scale,20*scale))
        lf = 1-abs(prog-0.5)*2
        if ct == 2:
            lf *= 0.5
        else:
            lf *= 0.7
        statPanel.fill(lighten(COLORS[ct],lf))


        for pos in range(digitLen(n+0.9)):
            thisDigit = digitAt(int(n),pos)
            nextDigit = digitAt(int(n)+1,pos)
            digitProg = prog
            if thisDigit == nextDigit:
                digitProg = 0

            thisDigitStr = str(thisDigit)
            nextDigitStr = str(nextDigit)
            if pos == 3:
                thisDigitStr += ","
                nextDigitStr += ","
            t_x = getXFromPos(pos)*scale
            t_c = TCOLORS[ct]
            if digitProg < 0.99:
                txt_surf = fontC.render(thisDigitStr, 1, t_c)
                statPanel.blit(txt_surf, (t_x, round(scale*(-1-18*digitProg))))
            if digitProg >= 0.01:
                txt_surf = fontC.render(nextDigitStr, 1, t_c)
                statPanel.blit(txt_surf, (t_x, round(scale*(17-18*digitProg))))
            if not isWorld:
                drawClock(statPanel,t_c,scale,co,timeFrac,ct)
        if ct >= 1 and prog >= 0.001 and prog < 0.999:
            xStart = 143+prog*64.5
            if ct == 1:
                pygame.draw.rect(countryPanel,TCOLORS[ct],(xStart,LOCS[ct][1]+4,20,12))
            pygame.draw.rect(countryPanel,COLORS[ct],(xStart,LOCS[ct][1]+5,20,10))
        countryPanel.blit(statPanel,LOCS[ct])

    if i >= 1 and not isWorld and LOC[0] < 600: # only the middle column gets these
        timeToSwap = co.currentCrossoverTime-timeFrac
        if timeToSwap >= 0 and timeToSwap < 36000:
            tstr = timeStr(timeToSwap)
            txt_surf1 = fontSmall.render("Swap",1,SWAP_COLOR)
            txt_surf2 = fontSmall.render("in "+tstr, 1, SWAP_COLOR)
            countryPanel.blit(txt_surf1,(345,12))
            countryPanel.blit(txt_surf2,(308,39))
            cx = 320.0
            cy = 20.0
            arrowScale = random.random()*4+5
            if timeToSwap > 0:
                arrowScale = 7+2*math.sin(math.sqrt(timeToSwap)*ARROW_PULSE_SPEED)
            vertices = np.array([[0,-2],[2,0],[1,0],[1,2],[-1,2],[-1,0],[-2,0]])
            scaledVertices = vertices*arrowScale+np.array([cx,cy])
            pygame.draw.polygon(countryPanel,SWAP_COLOR,scaledVertices)
    screen.blit(countryPanel,LOC)

def cosInterExtreme(a,b,x):
    x2 = 1
    if x < 0.2:
        x2 = 0
    elif x >= 0.2 and x < 0.8:
        prog = (x-0.2)/0.6
        x2 = 0.5-0.5*math.cos(prog*math.pi)
    else:
        x2 = 1
    return a+(b-a)*x2

def drawLeaderboard():
    global prevNowUR
    elapsed = (nowUR-prevNowUR)
    timeFrac = nowUR-nowR
    fac = min(1,TRANS_SPEED*elapsed)

    #windowsToGetTo = math.ceil((len(ranking)-TOP_TO_SHOW)/5)+1
    #WAN_RAW = (nowUR%120)/120*windowsToGetTo
    #WAN = int(WAN_RAW)+cosInterExtreme(0,1,WAN_RAW%1.0)-1

    minorView = getMinorView(timeFrac)

    for i in range(len(ranking)):
        c = ranking[i]
        co = countryData[c]

        countryData[c].updateAppData(fac, i, False)

        appRank = co.appData[3]
        if appRank < 9.99:
            drawBoxFor(i,c,co,elapsed, (460, 10+70*appRank),timeFrac,False)

        appRankAdjusted = appRank-minorView
        if appRankAdjusted >= -2.99 and appRankAdjusted < 3.3 and i >= 10:
            drawBoxFor(i,c,co,elapsed, (875, 360+70*(appRankAdjusted+2)),timeFrac,False)

    
    fractionDown = minorView/len(ranking)
    scrollH = 350
    barH = 70
    usableH = scrollH-barH
    pygame.draw.rect(screen,(20,20,20),(1245,360,20,scrollH))
    scrollY = 360+fractionDown*usableH
    pygame.draw.rect(screen,(140,140,140),(1245,scrollY,20,barH))
    
    pygame.draw.rect(screen,(0,0,0),(865,0,415,360))
    world.updateAppData(fac, -1, True)
    drawBoxFor(-1,"World",world,elapsed,(875,216),timeFrac,True)
    prevNowUR = nowUR

def drawOther():
    screen.blit(expla,(0,0))
    screen.blit(key,(875,0))
    time_surf = fontSmall.render("Right now: "+datetime.utcfromtimestamp(nowR).strftime('%B %d, %Y %H:%M:%S')+" UTC",1,(255,255,255))
    screen.blit(time_surf,(875,294))
    credit_surf = fontSmall.render("Vid by Cary Huang (youtube.com/1abacaba1)",1,(255,255,255))
    screen.blit(credit_surf,(875,320))

world = Country("World")
readLocalData()
initiateEverything()
screen = pygame.display.set_mode((1280,720))
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False

    setNows()
    if nowUR-lastCheckTime >= CHECK_WAIT_TIME:
        checkDataStream()
        lastCheckTime = nowUR

    if nowR-lastRankCheckTime >= RANK_CHECK_WAIT_TIME:
        secondlyUpdate(nowR)
        lastRankCheckTime = nowR



    screen.fill(BG_COLOR)
    drawLeaderboard()
    drawOther()

    pygame.display.flip()
