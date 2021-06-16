class Person{
  String name;
  float[] values = new float[DAY_LEN];
  int[] ranks = new int[DAY_LEN];
  String[] country = new String[DAY_LEN];
  color c;
  public Person(String n){
    name = n;
    for(int i = 0; i < DAY_LEN; i++){
      values[i] = 0;
      ranks[i] = TOP_VISIBLE+1;
      country[i] = "";
    }
    c = color(random(35,180),random(35,180),random(35,180));
  }
  color getColor(float currentDay){
    float prog = currentDay%1.0;
    color thisColor = getColor((int)currentDay);
    color nextColor = getColor(min((int)currentDay+1,DAY_LEN-1));
    return colorLerp(thisColor,nextColor,prog);
  }
  color getColor(int currentDay){
    int pd = max(0,currentDay-12); // Since one week ago
    float prevValue = 0;
    if(currentDay <= 12){
      prevValue = 0;///topTotals[pd]; // 2-year-trend   // values[pd]
    }else{
      prevValue = getAvgValue(pd);///topTotals[pd]; // 2-year-trend   // values[pd]
    }
    
    float currValue = getAvgValue(currentDay);///topTotals[currentDay];
    float logRatio = log(currValue/prevValue);
    if(logRatio < 0){
      return colorLerp(COLOR_MED, COLOR_COLD,-logRatio);
    }else{
      return colorLerp(COLOR_MED, COLOR_HOT,logRatio);
    }
  }
  float getAvgValue(int day){
    int start = max(0,day-2);
    int end = min(DAY_LEN-1,day+2);
    float summer = 0;
    float counter = 0;
    for(int d = start; d <= end; d++){
      counter++;
      summer += values[d];
    }
    return summer/counter;
  }
  color colorLerp(color a, color b, float px){
    float x = min(max(px,0),1);
    float newRed = red(a)+(red(b)-red(a))*x;
    float newGreen = green(a)+(green(b)-green(a))*x;
    float newBlue = blue(a)+(blue(b)-blue(a))*x;
    return color(newRed, newGreen,newBlue);
  }
}