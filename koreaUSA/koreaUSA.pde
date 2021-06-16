import java.util.*; 
import com.hamoid.*;
boolean KOREAN = true;
boolean PER_CAPITA = false;
boolean SAVE_VIDEO = true;
int PLAY_SPEED = 5;

String VIDEO_FILENAME = "test.mp4";
VideoExport videoExport;


String[] monthNames = {"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"};

int DAY_LEN;
int REGION_COUNT;
String[] textFile;
Region[] regions;
int TOP_VISIBLE = 15;
float[] maxes;
float[] topTotals;
int[] unitChoices;

float X_MIN = 120;
float X_MAX = 960;
float Y_MIN = 160;
float Y_MAX = 1040;
float X_W = X_MAX-X_MIN;
float Y_H = Y_MAX-Y_MIN;
float BAR_PROPORTION = 0.9;
int START_DATE = dateToDays("2020-01-21");
float TEXT_MARGIN = 8;

float currentScale = -1;

int frames = 0;
float currentDay = 0;
float FRAMES_PER_DAY = 50;
float BAR_HEIGHT;
PFont font;

int[] unitPresets = {1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000};

color COLOR_COLD = color(10,20,220);
color COLOR_MED = color(140,120,100);
color COLOR_HOT = color(240,30,30);

PImage flag;

void setup(){
  if(KOREAN){
    flag = loadImage("../../_flags/flag-of-S.-Korea.png");
  }else{
    flag = loadImage("../../_flags/flag-of-USA.png");
  }
  font = loadFont("Jygquif1-96.vlw");
  randomSeed(432766);
  String pstr = PER_CAPITA ? "p" : "";
  textFile = loadStrings("kusa"+pstr+".csv");
  String[] parts = textFile[0].split(",");
  DAY_LEN = parts.length-1;
  REGION_COUNT = textFile.length-1;
  
  maxes = new float[DAY_LEN];
  topTotals = new float[DAY_LEN];
  unitChoices = new int[DAY_LEN];
  for(int d = 0; d < DAY_LEN; d++){
    maxes[d] = 7;
  }
  
  regions = new Region[REGION_COUNT];
  //for(int i = 0; i < REGION_COUNT; i++){
  //  regions[i] = new Region(parts[i+1]);
  //}
  for(int p = 0; p < REGION_COUNT; p++){
    String[] dataParts = textFile[p].split(",");
    regions[p] = new Region(dataParts[0]);
    for(int d = 0; d < DAY_LEN; d++){
      float val = Float.parseFloat(dataParts[d+1]);
      regions[p].values[d] = val;
      if(val > maxes[d]){
        maxes[d] = val;
      }
    }
  }
  getRankings();
  for(int p = 0; p < REGION_COUNT; p++){
    for(int d = 0; d < DAY_LEN; d++){
      if((p < 17) == KOREAN){
        topTotals[d] += regions[p].values[d];
      }
    }
  }
  getUnits();
  BAR_HEIGHT = (rankToY(1)-rankToY(0))*BAR_PROPORTION;
  size(950,1080);
  //size(400,200);
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}
void draw(){
  currentDay = frames/FRAMES_PER_DAY+0;
  currentScale = getXScale(currentDay);
  
  drawBackground();
  
  drawHorizTickmarks();
  drawBars();
  
  noStroke();
  
  drawDate();
  saveImage();
  
  if(PER_CAPITA){
    drawCaseSummaryPerCapita();
  }else{
    drawCaseSummary();
  }
  
  saveImage();
  frames += PLAY_SPEED;
}
void drawCaseSummary(){
  int day = min(DAY_LEN-1,(int)round(currentDay));
  float val = topTotals[day];
  String s = commafy(val);
  float val2 = getTotal(topTotals,day);
  String s2 = commafy(val2);
  fill(255);
  textAlign(RIGHT);
  textFont(font,40);
  float Wm = width-20;
  String splur = (val == 1) ? "" : "s";
  text(s,Wm,height-448);
  text("case"+splur+" today",Wm,height-404);
  text("("+s2+" total)",Wm,height-360);
}
void drawCaseSummaryPerCapita(){
  float POP = KOREAN ? 51.64 : 328.2;
  float val = topTotals[min((int)round(currentDay),DAY_LEN-1)];
  String s = nf(val/POP,0,2);
  float val2 = getTotal(topTotals,(int)round(currentDay));
  String s2 = nf(val2/POP,0,2);
  if(val2/POP >= 999.995){
    s2 = commafy(val2/POP);
  }else if(val2/POP >= 99.995){
    s2 = nf(val2/POP,0,1);
  }
  fill(255);
  textFont(font,40);
  textAlign(RIGHT);
  float Wm = width-20;
  text(s,Wm,height-448);
  text("cases per M",Wm,height-404);
  text("("+s2+" / M total)",Wm,height-360);
}
void saveImage(){
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  println(currentDay+" / "+DAY_LEN);
  if(currentDay >= DAY_LEN){
    videoExport.endMovie();
    exit();
  }
}
float getTotal(float[] arr, int maxI){
  float sum = 0;
  for(int i = 0; i <= maxI; i++){
    sum += arr[min(i, arr.length-1)];
  }
  return sum;
}
String commafy(double f) {
  String s = (int)(Math.round(f))+"";
  String result = "";
  for (int i = 0; i < s.length(); i++) {
    if ((s.length()-i)%3 == 0 && i != 0) {
      result = result+",";
    }
    result = result+s.charAt(i);
  }
  return result;
}
void drawBackground(){
  background(0);
  fill(100);
  textAlign(CENTER);
  textFont(font,62);
  //text("Stack overflow posts with tag",840,Y_MIN-98);
}
void drawDate(){
  fill(255);
  textFont(font,96);
  textAlign(RIGHT);
  text("2020",width-20,height-40);
  text(daysToDate(currentDay,true,false),width-20,height-135);
  image(flag,width-192,height-330,flag.width*0.815,flag.height*0.815);
}
void drawHorizTickmarks(){
  float preferredUnit = WAIndex(unitChoices, currentDay, 1);
  float unitRem = preferredUnit%1.0;
  if(unitRem < 0.001){
    unitRem = 0;
  }else if(unitRem >= 0.999){
    unitRem = 0;
    preferredUnit = ceil(preferredUnit);
  }
  int thisUnit = unitPresets[(int)preferredUnit];
  int nextUnit = unitPresets[(int)preferredUnit+1];
  
  drawTickMarksOfUnit(thisUnit,255-unitRem*255);
  if(unitRem >= 0.001){
    drawTickMarksOfUnit(nextUnit,unitRem*255);
  }
  fill(100,100,100,255);
  textAlign(CENTER);
  textFont(font,62);
  String str = "Daily COVID-19 cases in US states";
  if(KOREAN){
    str = "Daily cases in South Korean provinces";
  }
  if(PER_CAPITA){
    str = "Daily cases in US states per 1M people";
    if(KOREAN){
      str = "Daily cases in SK provinces per 1M people";
      textFont(font,59);
    }
  }
  text(str,width/2,Y_MIN-97);
}
void drawTickMarksOfUnit(int u, float alpha){
  for(int v = 0; v < currentScale*1.4; v+=u){
    float x = valueToX(v);
    fill(100,100,100,alpha);
    float W = 4;
    rect(x-W/2,Y_MIN-20,W,Y_H+20);
    textAlign(CENTER);
    textFont(font,62);
    text(weirdify(v),x,Y_MIN-30);
  }
}
String weirdify(int v){
  if(PER_CAPITA){
    if(v%100 == 0){
      return keyify(v/100);
    }else if(v%10 == 0){
      return nf((float)v/100,0,1);
    }else{
      return nf((float)v/100,0,2);
    }
  }else{
    return keyify(v);
  }
}
void drawBars(){
  noStroke();
  for(int p = 0; p < REGION_COUNT; p++){
    Region pe = regions[p];
    float val = WAIndex(pe.values,currentDay,1);
    float x = valueToX(val);
    float rank = WAIndex(pe.ranks, currentDay, 1);
    float y = rankToY(rank);
    fill(pe.getColor(currentDay));
    rect(X_MIN,y,x-X_MIN,BAR_HEIGHT);
    fill(255);
    textFont(font,54);
    textAlign(RIGHT);
    String str = pe.name;
    if(x-X_MIN < 37){
      str += " ("+nf(val/100,0,1)+")";
    }
    float appX = max(x-TEXT_MARGIN,X_MIN+textWidth(str)+TEXT_MARGIN*2);
    text(str,appX,y+BAR_HEIGHT-8);
  }
  for(int r = 0; r < TOP_VISIBLE; r++){
    float y = rankToY(r);
    textFont(font,54);
    textAlign(RIGHT);
    text(rankify(r+1),X_MIN-10,y+BAR_HEIGHT-8);
  }
}
String rankify(int s){
  if(s >= 11 && s <= 19){
    return s+"th";
  }else if(s%10 == 1){
    return s+"st";
  }else if(s%10 == 2){
    return s+"nd";
  }else if(s%10 == 3){
    return s+"rd";
  }else{
    return s+"th";
  }
}
void getRankings(){
  for(int d = 0; d < DAY_LEN; d++){
    boolean[] taken = new boolean[REGION_COUNT];
    for(int p = 0; p < REGION_COUNT; p++){
      taken[p] = false;
    }
    for(int spot = 0; spot < TOP_VISIBLE; spot++){
      float record = -1;
      int holder = -1;
      for(int p = 0; p < REGION_COUNT; p++){
        if((p < 17) == KOREAN){
          if(!taken[p]){
            float val = regions[p].values[d];
            if(val > record){
              record = val;
              holder = p;
            }
          }
        }
      }
      if(regions[holder].values[d] >= 1){
        regions[holder].ranks[d] = spot;
      }
      taken[holder] = true;
    }
  }
}
float stepIndex(float[] a, float index){
  return a[(int)index];
}
float linIndex(float[] a, float index){
  int indexInt = (int)index;
  float indexRem = index%1.0;
  float beforeVal = a[indexInt];
  float afterVal = a[indexInt+1];
  return lerp(beforeVal,afterVal,indexRem);
}
float WAIndex(float[] a, float index, float WINDOW_WIDTH){
  /*float start = a[(int)index];
  float end = a[min(a.length-1,(int)(index+1))];
  float prog = min(max((index%1.0)*2,0),1);
  return start+(end-start)*prog;*/
  
  int startIndex = max(0,ceil(index-WINDOW_WIDTH));
  int endIndex = min(DAY_LEN-1,floor(index+WINDOW_WIDTH));
  float counter = 0;
  float summer = 0;
  for(int d = startIndex; d <= endIndex; d++){
    float val = a[d];
    float weight = 0.5+0.5*cos((d-index)/WINDOW_WIDTH*PI);
    counter += weight;
    summer += val*weight;
  }
  float finalResult = summer/counter;
  return finalResult;
}
float WAIndex(int[] a, float index, float WINDOW_WIDTH){
  float[] aFloat = new float[a.length];
  for(int i = 0; i < a.length; i++){
    aFloat[i] = a[i];
  }
  return WAIndex(aFloat,index,WINDOW_WIDTH);
}

float getXScale(float d){
  return WAIndex(maxes,d,1)*1.1;
}
float valueToX(float val){
  return X_MIN+X_W*val/currentScale;
}
float rankToY(float rank){
  float y = Y_MIN+rank*(Y_H/TOP_VISIBLE);
  return y;
}
String daysToDate(float daysF, boolean longForm, boolean incYear){
  int days = (int)round(daysF)+START_DATE;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  if(!incYear){
    return monthNames[month-1]+" "+date;
  }
  if(longForm){
    return year+" "+monthNames[month-1]+" "+date;
  }else{
    return year+"-"+nf(month,2,0)+"-"+nf(date,2,0);
  }
}
String daysToNumericDate(int daysF){
  int days = daysF+2008*12+6;
  int month = days%12;
  int year = days/12;
  return year+"-"+nf(month+1,2,0);
}
int dateToDays(String s){
  int year = Integer.parseInt(s.substring(0,4))-1900;
  int month = Integer.parseInt(s.substring(5,7))-1;
  int date = Integer.parseInt(s.substring(8,10));
  Date d1 = new Date(year, month, date, 6, 6, 6);
  int days = (int)(d1.getTime()/86400000L);
  return days;
}
int dateToDaysShort(String s){
  return dateToDays(s)-START_DATE;
}
void getUnits(){
  for(int d = 0; d < DAY_LEN; d++){
    float Xscale = getXScale(d);
    for(int u = 0; u < unitPresets.length; u++){
      if(unitPresets[u] >= Xscale/3.0){ // That unit was too large for that scaling!
        unitChoices[d] = u-1; // Fidn the largest unit that WASN'T too large (i.e., the last one.)
        break;
      }
    }
  }
}
String keyify(int n){
  if(n < 1000){
    return n+"";
  }else if(n < 1000000){
    if(n%1000 == 0){
      return (n/1000)+"K";
    }else{
      return nf(n/1000f,0,1)+"K";
    }
  }
  if(n%1000000 == 0){
    return (n/1000000)+"M";
  }else{
    return nf(n/1000000f,0,1)+"M";
  }
}
