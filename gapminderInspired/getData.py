import os
import time
import urllib.request
from urllib.request import Request, urlopen

SECONDS_IN_BETWEEN_REQUESTS = 6  # If you sent this to 6, the code will wait 6 seconds between loading each page. If you set it to 0.1, it'll only wait 0.1 seconds! However, I set it to 6 so my IP won't get blocked for DDOSing.
GETTING_US_STATE_DATA = False  # If true, we'll get worldometer's data on US states. Otherwise, we'll get data on all countries of the world.

if GETTING_US_STATE_DATA:
    if not os.path.exists('usStateData'):
        os.makedirs('usStateData')
    f = open("usStateList.tsv", "r+")
else:
    if not os.path.exists('countryData'):
        os.makedirs('countryData')
    f = open("countryList.tsv", "r+")
lines = f.read().split("\n")
f.close()

counter = 0
for i in range(0, len(lines)):
    line = lines[i]
    if len(line) >= 2:
        parts = line.split("\t")
        name = parts[0]
        if GETTING_US_STATE_DATA:
            url = "https://www.worldometers.info/coronavirus/usa/" + name + "/"
        else:
            url = "https://www.worldometers.info/coronavirus/country/" + name + "/"

        req = Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        webpage = urlopen(req).read()

        if GETTING_US_STATE_DATA:
            FILENAME = "usStateData/" + name + ".html"
        else:
            FILENAME = "countryData/" + name + ".html"
        f = open(FILENAME, "wb")
        f.write(webpage)
        f.close()

        time.sleep(SECONDS_IN_BETWEEN_REQUESTS)
        counter += 1
        print("Done downloading " + str(counter) + " / " + str(len(lines)) + "    (" + name + ")")
