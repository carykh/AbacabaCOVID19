import math

"""f = open("pool.tsv","w+")
cum = 0
for i in range(365):
    daily = 3868/365
    fac = 1-math.sin((i/365*2)*math.pi)*0.75
    cum += daily*fac
    f.write(str(int(round(cum)))+",")
f.flush()
f.close()"""

"""f = open("car.tsv","w+")
cum = 0
for i in range(365):
    daily = 40231/365
    fac = 1
    cum += daily*fac
    f.write(str(int(round(cum)))+",")
f.flush()
f.close()"""

f = open("brazil_flu.tsv", "w+")
cum = 0
for i in range(366):
    daily = 2116 / 365
    fac = 1 - math.cos((i / 365 * 2) * math.pi) * 0.4
    cum += daily * fac
    f.write(str(int(round(cum))) + ",")
f.flush()
f.close()
