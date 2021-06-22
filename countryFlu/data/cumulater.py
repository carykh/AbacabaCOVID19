f = open("COVID19_deaths_india.csv","r+")
result = f.read().split(",")
f.close()

summ = 0
stri = ""
for i in range(len(result)):
    summ += int(result[i])
    stri += str(summ)+","
print(stri)