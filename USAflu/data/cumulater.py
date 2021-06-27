f = open("COVID19_USA_daily_deaths_since_2020-10-01.csv", "r+")
result = f.read().split(",")
f.close()

summ = 0
stri = ""
for i in range(len(result)):
    summ += int(result[i])
    stri += str(summ) + ","
print(stri)
