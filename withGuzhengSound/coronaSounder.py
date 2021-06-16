from scipy.io.wavfile import read
from scipy.io.wavfile import write
from scipy import ndimage
from scipy import misc
import numpy as np
import math
import random

TIMETABLE_FILE = "chinaCOVID19deathCount.txt"
OUTPUT_FILE = "chinaCOVID19deathCount.wav"
SOUND_FILES = "sounds/guzheng"

f = open(TIMETABLE_FILE,"r+",encoding="utf-8")
lines = f.read().split("\n")
f.close()

lengthInSeconds = int(5*60)
sampleRate = 44100
totalSampleCount = lengthInSeconds*sampleRate

totalAudio = np.zeros((totalSampleCount,2))

bell = []
bellLength = []

for z in range(6):
    _, bella = read(SOUND_FILES+str(z)+".wav")
    bell.append(bella)
    bellLength.append(len(bella))

for i in range(len(lines)):
    line = lines[i]
    if len(line) >= 1:
        time = int(line)
        choice = bell[i%6]
        totalAudio[time:time+len(choice)] += choice
    if i%100 == 0:
        print("Done with "+str(i))
    
totalAudio /= np.amax(totalAudio)

write(OUTPUT_FILE, sampleRate, totalAudio)
print("Done!")