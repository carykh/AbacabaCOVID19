import java.math.*;
import com.hamoid.*;
boolean SAVE_VIDEO = true;
String VIDEO_FILENAME = "test.mp4";
VideoExport videoExport;

String[] data;
String[] newsData;
String[] newsCountsStr;
String[] dowDataStr;
int[] newsCounts;
int[] countryCounts;
float[] dowData;
int[] dowDataSimple;
int DAY_LEN = 68;
int DOW_EXTENSION = 64;
int CASE_TYPES = 3; // recovered, active, death
Country[] countries;
Country world;
int COUNTRY_COUNT = 91;

float BG_SHADE = 85;
PFont titleFont;
PFont contentFont;
PFont titleFontSmall;
PFont contentFontSmall;
PFont titleFontBig;
PFont contentFont44;
color[] cols = {
  color(0,255,255,255),color(180,160,30,255),color(114,0,0,255),color(0,0,0),
color(0,0,0),color(0,0,0),color(255,255,255),color(255,255,255)};
ArrayList<Integer> finalRanking;
PImage nyt;
PImage worldImage;
PImage countryImage;
PImage watermark;

PrintWriter deathsText;

float W_W = 1920;
float W_H = 1080;

void setup(){
  nyt = loadImage("nyt.jpg");
  worldImage = loadImage("world.png");
  countryImage = loadImage("country.png");
  watermark = loadImage("watermark.png");
  titleFont = loadFont("GothamNarrow-Black-54.vlw");
  contentFont = loadFont("Gotham-Medium-36.vlw");
  contentFont44 = loadFont("Gotham-Medium-44.vlw");
  titleFontSmall = loadFont("GothamNarrow-Black-40.vlw");
  contentFontSmall = loadFont("Gotham-Medium-27.vlw");
  titleFontBig = loadFont("GothamNarrow-Black-100.vlw");
  data = loadStrings("virusData.csv");
  newsData = loadStrings("COVIDarticles.txt");
  newsCountsStr = loadStrings("COVIDarticleCounts.txt");
  dowDataStr = loadStrings("dowData.txt");
  newsCounts = new int[DAY_LEN];
  countryCounts = new int[DAY_LEN];
  dowData = new float[DOW_EXTENSION+DAY_LEN];
  dowDataSimple = new int[DOW_EXTENSION+DAY_LEN];
  for(int day = 0; day < DAY_LEN; day++){
    String nc = newsCountsStr[day];
    newsCounts[day] = Integer.parseInt(nc.substring(0,nc.indexOf(",")));
    countryCounts[day] = 0;
  }
  println(DOW_EXTENSION+DAY_LEN);
  println(dowDataStr.length);
  for(int day = 0; day < DOW_EXTENSION+DAY_LEN; day++){
    dowData[day] = Float.parseFloat(dowDataStr[day]);
    dowDataSimple[day] = (int)round(dowData[day]);
  }
  countries = new Country[COUNTRY_COUNT];
  for(int c = 0; c < COUNTRY_COUNT; c++){
    countries[c] = new Country(false);
  }
  world = new Country(true);
  
  String[] indices = data[1].split(",");
  String[] names = data[2].split(",");
  String[] pops = data[3].split(",");
  String[] codes = data[4].split(",");
  for(int day = 0; day < DAY_LEN; day++){
    String[] dayParts = data[day+5].split(",");
    for(int r = 1; r < dayParts.length; r++){
      int c = Integer.parseInt(indices[r]);
      if(c >= 0){
        Country co = countries[c];
        if(co.name.equals("")){
          co.setName(names[r]);
          co.code = codes[r];
          co.pop = Integer.parseInt(pops[r]);
        }
        String s = dayParts[r];
        String[] miniParts = s.split("-");
        if(miniParts.length <= 2 && miniParts[0].length() >= 1){
          co.data[1][day] += Integer.parseInt(miniParts[0]);
        }else if(miniParts.length == 3){
          int total = Integer.parseInt(miniParts[0]);
          int recovered = Integer.parseInt(miniParts[2]);
          co.data[1][day] += total-recovered;
          co.data[0][day] += recovered;
        }else if(miniParts.length == 4){
          int total = Integer.parseInt(miniParts[0]);
          int recovered = Integer.parseInt(miniParts[2]);
          int deaths = Integer.parseInt(miniParts[3]);
          co.data[1][day] += total-recovered-deaths;
          co.data[0][day] += recovered;
          co.data[2][day] += deaths;
        }
        if(co.name.equals("thailand") && co.data[1][day] < 0){
          co.data[1][day] = 14;
        }
        co.setCums(day);
      }
    }
  }
  countries[0].average(28);
  countries[0].average(31);
  countries[30].average(61);
  for(int day = 0; day < DAY_LEN; day++){
    ArrayList<Integer> rankings = new ArrayList<Integer>(0);
    for(int c = 0; c < COUNTRY_COUNT; c++){
      Country co = countries[c];
      co.setPC(day);
      int index = findSpotFor(rankings,co.getRankingValue(day),day);
      rankings.add(index,c);
      for(int ct = 0; ct < 3; ct++){
        //if(c >= 1){
          world.data[ct][day] += co.data[ct][day];
        //}
      }
      if(co.data[1][day] >= 1){
        countryCounts[day]++;
      }
    }
    int firstNonexistent = -1;
    for(int rank = 0; rank < COUNTRY_COUNT; rank++){
      int c = rankings.get(rank);
      countries[c].ranks[day] = rank;
      if(countries[c].data[1][day] == 0){
        if(firstNonexistent == -1){
          firstNonexistent = rank;
        }
        countries[c].ranks[day] = firstNonexistent;
      }
    }
    for(int c = 0; c < COUNTRY_COUNT; c++){
      float perc = ((float)countries[c].data[1][day])/world.data[1][day];
      countries[c].cpt[day] = round(perc*1000);
    }
    if(day == DAY_LEN-1){
      finalRanking = rankings;
    }
  }
  size(1920,1080);
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
  noStroke();
}
double FRAMES_PER_DAY = 25;
int frames = 0;//36*60;
double currentDay = 0;
int currentDayInt = 0;
double currentDayProg = 0;
double currentDaySim = 0;
int CDIA = 0;
void draw(){
  setDayVars();
  
  //scale(0.75);
  //translate(-1570,0);
  
  drawBG();
  /*fill(255,0,255);
  noStroke();
  rect(0,W_H,W_W*2,W_H);
  rect(W_W,0,W_W,W_H*2);*/
  
  drawWidgets();
  drawWorldWidget();
  
  drawDowGraph(1605,539,315,143);
  //fill(128,0,128);
  //rect(width*0.51,height*0.6,width*0.49,height*0.2);
  drawNews();
  image(watermark,0,0);
  
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  if(frames >= (DAY_LEN-1.0)*FRAMES_PER_DAY){
    videoExport.endMovie();
    exit();
  }
  frames++;
}
void drawDowGraph(float x, float y, int w, int h){
  fill(BG_SHADE);
  rect(x,y,w,h+7);
  PGraphics graph = createGraphics(w,h);
  graph.beginDraw();
  graph.background(0);
  for(int dt = 26; dt <= 30; dt++){
    float lineY = dowValToY(dt*1000,h);
    graph.stroke(255,255,255,50);
    graph.strokeWeight(3);
    float minX = 0;
    if(dt == 26){
      minX = 155;
    }else if(dt == 30){
      minX = 165;
    }
    graph.line(minX,lineY,w,lineY);
  }
  for(int d = 0; d < DOW_EXTENSION+DAY_LEN-1; d++){
    float x1 = dowDayToX(d,w);
    float y1 = dowValToY(dowData[d],h);
    float x2 = dowDayToX(d+1,w);
    float y2 = dowValToY(dowData[d+1],h);
    if(x1 < w && x2 >= 0){
      graph.noStroke();
      graph.fill(255,0,255,100);
      graph.beginShape();
      graph.vertex(x1,y1);
      graph.vertex(x2,y2);
      graph.vertex(x2,h);
      graph.vertex(x1,h);
      graph.endShape(CLOSE);
      graph.stroke(255,0,255);
      graph.strokeWeight(3);
      graph.line(x1,y1,x2,y2);
    }
  }
  graph.fill(255);
  graph.textFont(contentFontSmall,27);
  graph.textAlign(LEFT);
  graph.text("Dow Jones",7,30);
  graph.image(drawRollingText(2,dowDataSimple,200,46,1.0,0,DOW_EXTENSION),7,h-46);
  graph.endDraw();
  image(graph,x,y);
}
float dowDayToX(int day, float w){
  double frac = (currentDaySim-(day-DOW_EXTENSION))/48.0;
  return (float)Math.round(w-frac*w);
}
float dowValToY(float dow, float h){
  float frac = (dow-25200)/(31130-25200);
  return h-frac*h;
}
int getDigitOf(int num, int pos){
  for(int p = 0; p < pos; p++){
    num = num/10;
  }
  return num%10;
}
int getWeightOf(int num, int pos, int abbr){
  if(abbr == 1 && pos < 3 && num >= 1000){
    num = 1000;
  }
  for(int p = 0; p < pos; p++){
    num = num/10;
  }
  return num;
}
int getLength(int num){
  if(num == 0){
    return 1;
  }
  int len = 0;
  while(num > 0){
    num = num/10;
    len++;
  }
  return len;
}
double getAppLength(int num, int abbr){
  int len = getLength(num);
  if(abbr == 2){
    len = max(2,len);
  }
  double extra = 0.0;
  if((abbr == 0 && len > 3) || abbr == 2){
    extra = 0.4;
  }
  return len+extra;
}
PGraphics drawRollingText(int ct, int[] arr, int w, int h, float tScale, int abbr, int indexOffset){
  // abbr: 0 = full length count, 1 = abbreviated count, 2 = percentage
  int thisVal = arr[currentDayInt+indexOffset];
  int nextVal = arr[min(DAY_LEN-1,currentDayInt+1)+indexOffset];
  
  if(abbr == 1){
    if(thisVal >= 1500 && thisVal%1000 >= 500){
      thisVal = (int)(1000*ceil(thisVal/1000.0));
    }
    if(nextVal >= 1500 && nextVal%1000 >= 500){
      nextVal = (int)(1000*ceil(nextVal/1000.0));
    }
  }
  
  PGraphics t = createGraphics(w,h);
  t.beginDraw();
  t.scale(tScale);
  t.textFont(contentFont,36);
  t.fill(cols[ct+4]);
  t.textAlign(CENTER);
  for(int pos = 0; pos < 5; pos++){
    int start = getWeightOf(thisVal,pos,abbr);
    int end = getWeightOf(nextVal,pos,abbr);
    double startLen = getAppLength(thisVal,abbr);
    double endLen = getAppLength(nextVal,abbr);
    double appLen = snapInter(startLen,endLen,currentDayProg);
    double appNum = snapInter(start,end,currentDayProg);
    String thisDigit = (int)(appNum%10)+"";
    String nextDigit = (int)((appNum+1)%10)+"";
    if(abbr == 1 && pos < 3){
      if(appNum >= Math.pow(10,3-pos)){
        thisDigit = (pos == 2) ? "K" : "";
      }
      if(appNum+1 >= Math.pow(10,3-pos)){
        nextDigit = (pos == 2) ? "K" : "";
      }
    }
    double prog = appNum%1.0;
    double appPos = pos;
    if(pos >= 3 && abbr == 0){
      appPos += 0.4;
    }else if(pos >= 1 && abbr == 2){
      appPos += 0.4;
    }
    
    float thisX = (float)((appLen-1-appPos)*25+13);
    float nextX = thisX;
    if(thisDigit.equals("K")){
      thisX += 2;
    }
    if(nextDigit.equals("K")){
      nextX += 2;
    }
    boolean isVisibleZero = ((abbr <= 1 && pos == 0) || (abbr == 2 && pos <= 1));
    if(appNum >= 1 || isVisibleZero){
      t.text(thisDigit,thisX,35-Math.round(37*prog));
    }
    t.text(nextDigit,nextX,72-Math.round(37*prog));
    if(pos == 3 && abbr == 0){
      double commaPos = appPos-0.7;
      t.text(",",(float)((appLen-1-commaPos)*25+13),35);
    }else if(pos == 1 && abbr == 2){
      double periodPos = appPos-0.7;
      t.text(".",(float)((appLen-1-periodPos)*25+13),35);
    }else if(pos == 0 && abbr == 2){
      double percentPos = appPos-1.2;
      t.text("%",(float)((appLen-1-percentPos)*25+13),35);
    }
    
  }
  t.endDraw();
  return t;
}
void drawNews(){
  float usableH = W_H*0.2;
  double dipFactor = Math.abs(1-snapInter(0,2,currentDayProg));
  if((currentDayProg < 0.5 && CDIA < DAY_LEN-1 && newsCounts[CDIA] == 0 && newsCounts[CDIA+1] == 0) ||
  (currentDayProg >= 0.5 && CDIA >= 1 && newsCounts[CDIA-1] == 0 && newsCounts[CDIA] == 0)){
    dipFactor = 1;
  }
  fill(0);
  pushMatrix();
  translate(W_W*0.475,W_H*0.8);
  rect(0,0,W_W*0.525,usableH);
  
  float marg = W_H*0.01;
  float imgH = W_H*0.141;
  float imgW = imgH/nyt.height*nyt.width;
  float usableW = W_W*0.525-imgW-marg*3;
  image(nyt,marg,marg,imgW,imgH);
  fill(128);
  textFont(contentFontSmall,27);
  textAlign(LEFT);
  int nc = newsCounts[CDIA];
  pushMatrix();
  translate(0,(float)(45-45*dipFactor));
  String s = "s";
  if(nc == 1){
    s = "";
  }
  text(nc+" article"+s,marg,198);
  popMatrix();
  
  String title = newsData[CDIA*5+3];
  String content = newsData[CDIA*5+1];
  String author = newsData[CDIA*5+4];
  
  pushMatrix();
  float yDisp = (float)(usableH-usableH*dipFactor);
  translate(0,round(yDisp));
  fill(255);
  textFont(titleFontSmall,40);
  int startY = 76;
  float tx = imgW+marg*2;
  if(printMultiLines(title,tx,44,40,usableW,2) == 2){
    startY = 116;
  }
  textFont(contentFontSmall,27);
  fill(128);
  text(author,tx,startY-2);
  fill(255);
  textFont(contentFontSmall,27);
  printMultiLines(content,tx,startY+28,27,usableW,3);
  popMatrix();
  popMatrix();
}
int printMultiLines(String s, float tx, float ty, float inc, float usableW, int linesLeft){
  if(textWidth(s) <= usableW || linesLeft <= 1){
    text(s,tx,ty);
    return 1;
  }else{
    int firstBreak = 0;
    while(s.indexOf(" ",firstBreak+1) >= 0 && textWidth(s.substring(0,s.indexOf(" ",firstBreak+1))) <= usableW){
      firstBreak = s.indexOf(" ",firstBreak+1);
    }
    String titleP1 = s.substring(0,firstBreak);
    String titleP2 = s.substring(firstBreak+1,s.length());
    text(titleP1,tx,ty);
    return printMultiLines(titleP2,tx,ty+inc,inc,usableW,linesLeft-1)+1;
  }
}
void setDayVars(){
  int dFrames = frames; // "de facto"
  int dFPD = (int)FRAMES_PER_DAY;
  currentDay = ((float)dFrames)/dFPD;
  currentDayInt = (int)currentDay;
  currentDayProg = currentDay%1.0;
  CDIA = (int)(currentDay+0.5);
  currentDaySim = currentDayInt+snapInter(0,1,currentDayProg);
}
void drawBG(){
  background(BG_SHADE);
  fill(255);
  textAlign(RIGHT);
  textFont(contentFont44,44);
  text("COVID-19 on",W_W-28,62);
  textFont(titleFontBig,100);
  
  text(dayToDateString(CDIA),W_W-28,152);
  text(dayToYearString(CDIA),W_W-26,245);
}
void drawWidgets(){
  float[][] SWC = // smallWidgetConfiguration
  //{{81,85,0.8445,1,20},{86,90,0.911,1,20}};
  {{6,30,0.531,0,0},{31,55,0.7115,1,0},{56,80,0.778,1,0},
  {81,85,0.8445,1,20},{86,90,0.911,1,20}};
  
  
  for(int i = 0; i < COUNTRY_COUNT; i++){
    int c = finalRanking.get(finalRanking.size()-1-i);
    Country co = countries[c];
    double thisScale = (co.data[1][currentDayInt] >= 1) ? 1 : 0;
    double nextScale = (co.data[1][min(currentDayInt+1,DAY_LEN-1)] >= 1) ? 1 : 0;
    double trueScale = snapInter(thisScale,nextScale,currentDayProg);
    if(trueScale > 0){
      double rank = snapIndex(co.ranks, currentDay);
      if(rank < 5){ // Ranks 1 - 5 
        pushMatrix();
        translate(0,(float)(rank*214+4));
        scale((float)trueScale);
        co.drawBigWidget(false);
        popMatrix();
      }
      for(int conf = 0; conf < SWC.length; conf++){
        int lowerR = (int)SWC[conf][0];
        int higherR = (int)SWC[conf][1];
        float shiftX = SWC[conf][2];
        boolean abbr = (SWC[conf][3] == 1);
        float startY = (int)SWC[conf][4];
        if(rank > lowerR-2 && rank < higherR){
          pushMatrix();
          translate(W_W*shiftX,(float)((startY+rank-(lowerR-1))*33.8+16));
          scale((float)trueScale);
          co.drawSmallWidget(abbr);
          popMatrix();
        }
      }
      
      fill(BG_SHADE);
      rect(W_W*0.475,0,W_W*0.5,16-4);
      float bottomEdge = 16+25*33.8-2;
      rect(W_W*0.475,bottomEdge,W_W*0.525,W_H-bottomEdge);
      //bottomEdge = 16+20*32.5-2;
      //rect(width*0.7,bottomEdge,width*0.3,height-bottomEdge);
    }
  }
}
void drawWorldWidget(){
  pushMatrix();
  translate(W_W,370);
  world.drawBigWidget(true);
  image(worldImage,-310,-35,120,120);
  textAlign(CENTER);
  fill(255);
  textFont(contentFontSmall,27);
  text("WORLD",-250,117);
  text("TOTAL",-250,149);
  image(countryImage,-55,-42,38,38);
  popMatrix();
}
int findSpotFor(ArrayList<Integer> rankings, float val, int day){
  return findSpotFor(rankings,val,day,0,rankings.size()-1);
}
int findSpotFor(ArrayList<Integer> rankings, float val, int day, int s, int e){
  if(s > e){
    return s;
  }
  int mid = (s+e)/2;
  float compareTo = countries[rankings.get(mid)].getRankingValue(day);
  if(val == compareTo){
    return mid;
  }else if(val < compareTo){
    return findSpotFor(rankings,val,day,mid+1,e);
  }else{
    return findSpotFor(rankings,val,day,s,mid-1);
  }
}
String capitalize(String s){
  String result = "";
  for(int i = 0; i < s.length(); i++){
    if(i == 0 || (i >= 1 && s.charAt(i-1) == ' ')){
      result = result+s.toUpperCase().charAt(i);
    }else{
      result = result+s.charAt(i);
    }
  }
  return result;
}
double dlerp(double a, double b, double x){
  return a+(b-a)*x;
}
double snapIndex(double[] a, double index){
  int indexInt = (int)index;
  double indexRem = snapInter(0,1,index%1.0);
  double beforeVal = a[indexInt];
  double afterVal = a[min(indexInt+1,DAY_LEN-1)];
  return dlerp(beforeVal,afterVal,indexRem);
}
double snapIndex(int[] a, double index){
  int indexInt = (int)index;
  double indexRem = snapInter(0,1,index%1.0);
  double beforeVal = a[indexInt];
  double afterVal = a[min(indexInt+1,DAY_LEN-1)];
  return dlerp(beforeVal,afterVal,indexRem);
}
double snapInter(double a, double b, double x){
  if(x < 0.5){
    double prog = Math.max(Math.pow(x,7.7)/Math.pow(0.5,6.7),0.0000000000001);
    return dlerp(a,b,prog);
  }else{
    double prog = Math.min(Math.pow(1-x,7.7)/Math.pow(0.5,6.7),0.9999999999999);
    return dlerp(b,a,prog);
  }
}
String commafy(float f) {
  String s = round(f)+"";
  String result = "";
  for (int i = 0; i < s.length(); i++) {
    if ((s.length()-i)%3 == 0 && i != 0) {
      result = result+",";
    }
    result = result+s.charAt(i);
  }
  return result;
}
String dayToDateString(int day){
  if(day == 0){
    return "Dec 31";
  }else if(day <= 31){
    return "Jan "+day;
  }else if(day <= 60){
    return "Feb "+(day-31);
  }else{
    return "Mar "+(day-60);
  }
}
String dayToYearString(int day){
  if(day == 0){
    return "2019";
  }else{
    return "2020";
  }
}
String abbrNumber(int n){
  if(n < 1000){
    return n+"";
  }else if (n < 999500){
    return round(n/1000.0)+"K";
  }else if (n < 999500000){
    return round(n/1000000.0)+"M";
  }else{
    return round(n/1000000000.0)+"B";
  }
}
