import java.util.HashMap;
import java.io.*; 
import java.util.*; 
import com.hamoid.*;
boolean SAVE_VIDEO = true;
boolean SHOW_EPITAPHS = false;
int SPEED_MULTIPLIER = 2;
String VIDEO_FILENAME = "test.mp4";
VideoExport videoExport;
// the animation stops once it's fully zoomed in on the squares of the rightmost pillar of USA. Reverse the outputted video to get the zoom-out.

HashMap<String, String> trueCountries = new HashMap<String, String>();
ArrayList<Country> countries = new ArrayList<Country>();

int START_DATE = dateToDays("2020-01-03");
String[] data;
String[] TCdata;
int WEEK_COUNT;
int COUNTRY_COUNT = 400;
float W_W = 1920;
float W_H = 1080;
int[] totals;
PFont fontMain;
PImage gravestone;
int DIW = 7; // days in week
String[] comparableData;
Comparable[] comparables;
int COMP_COUNT = 0;
color[] cols = {color(50,150,50),color(50,50,150),color(200,50,50)};
float[] zoomScales;

float MIN_Y = 90;
float MAX_Y = 990;
float MAX_X = 1150;
float BAR_DIST = 350;
float BOX_SIZE = 6;
int BAR_W = 50;
float MAX_ZOOM = 1.333333;

int EPITAPH_COUNT = 2700;
String[] names;
String[] lovedBy = {"children","grandkids","friends","husband","wife","family"};
String[][] epitaphs = new String[EPITAPH_COUNT][3];

float FRAMES_PER_WEEK = 8*60;
float currentWeek = 0;
int currentWeekInt = 0;
float currentWeekRem = 0;
float TIME_DIV_A = 0.214;
float TIME_DIV_B = 0.70;
float TIME_DIV_C = 0.80;
int FRAME_START = 0;//(int)((WEEK_COUNT-1+TIME_DIV_C)*FRAMES_PER_WEEK);
int ZOOM_IN_AT = 0;
int frames = FRAME_START;



int nzFrames = 0;
float nzoom = 1.0;
float NZOOM_X = 1435.8;
float NZOOM_Y = 974.45;
float textAlpha = 0;


void setup(){
  randomSeed(138);
  names = loadStrings("names.txt");
  for(int i = 0; i < EPITAPH_COUNT; i++){
    int choice = (int)random(0,400);
    String p1 = names[choice].split(",")[0];
    String p2 = " "+(char)((int)random(65,91))+".";
    String p3 = "";
    if(random(0,1) < 0.5){
      choice = (int)random(0,2);
      int count = (int)random(2+choice,5+4*choice);
      p3 = count+" "+lovedBy[choice];
    }else{
      choice = (int)random(2,6);
      p3 = lovedBy[choice];
    }
    epitaphs[i][0] = p1+p2;
    epitaphs[i][1] = "Loved by";
    epitaphs[i][2] = p3;
  }
  
  gravestone = loadImage("gravestone.png");
  fontMain = loadFont("GothamNarrow-Black-108.vlw");
  TCdata = loadStrings("subCountryInfo.csv");
  for(int i = 0; i < TCdata.length; i++){
    String[] parts = TCdata[i].split(",");
    trueCountries.put(parts[0].toLowerCase(),parts[1].toLowerCase());
  }
  comparableData = loadStrings("comparables.csv");
  COMP_COUNT = comparableData.length;
  comparables = new Comparable[COMP_COUNT];
  for(int i = 0; i < COMP_COUNT; i++){
    String[] parts = comparableData[i].split(";");
    comparables[i] = new Comparable(parts[0],parts[1],parts[2],cols[i%cols.length],Integer.parseInt(parts[3]));
  }
  
  data = loadStrings("virusData.csv");
  WEEK_COUNT = ceil(data.length/DIW)+3;
  totals = new int[WEEK_COUNT];
  zoomScales = new float[WEEK_COUNT];
  for(int week = 0; week < WEEK_COUNT; week++){
    totals[week] = 0;
  }
  String[] countryNames = data[0].split(",");
  for(int i = 1; i < countryNames.length; i++){
    String n = fix(countryNames[i]);
    if(!n.equals("na")){
      int indie = getIndexOf(n);
      if(indie < 0){
        countries.add(-1-indie,new Country(n));
      }
    }
  }
  for(int line = 2; line < data.length-1; line+=DIW){
    String[] parts = data[line+1].split(",");
    for(int p = 1; p < parts.length; p++){
      String n = fix(countryNames[p]);
      if(!n.equals("na")){ 
        Country thisCountry = countries.get(getIndexOf(n));
        String datum = parts[p];
        String[] miniParts = datum.split("-");
        if(miniParts.length == 4){
          int deaths = Integer.parseInt(miniParts[3]);
          thisCountry.deaths[line/DIW+2] += deaths;
        }
      }
    }
  }
  for(int week = 0; week < WEEK_COUNT; week++){
    int cum = 0;
    for(int i = 0; i < countries.size(); i++){
      Country c = countries.get(i);
      int newDeaths = c.getNewDeaths(week);
      c.startEnd[week][0] = cum;
      c.startEnd[week][1] = cum+newDeaths;
      cum += newDeaths;
    }
    totals[week] = cum;
    int ctsa = 0; // comp to stop at
    while(comparables[ctsa].deaths < totals[week]){
      ctsa++;
    }
    float barHeight = ((float)comparables[ctsa].deaths)/BAR_W*BOX_SIZE;
    float scaleToBigBy = barHeight/(MAX_Y-MIN_Y);
    zoomScales[week] = min(MAX_ZOOM,1/scaleToBigBy);
    if(week >= 1){
      zoomScales[week] = min(zoomScales[week],zoomScales[week-1]);
    }
  }
  ZOOM_IN_AT = (int)((WEEK_COUNT-1+TIME_DIV_C)*FRAMES_PER_WEEK);
  noiseSeed(1);
  size(1920,1080);
  noSmooth();
  frameRate(60);
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}

void draw(){
  float preNZoom = 0;
  if(nzFrames < 420){
    preNZoom = cosInter(0,log(4.4)/log(10),nzFrames/240.0);
  }else if(nzFrames < 480){
    preNZoom = log(4.4)/log(10);
  }else{
    preNZoom = cosInter(log(4.4)/log(10),log(300)/log(10),(nzFrames-480.0)/780.0);
  }
  textAlpha = 255*min(max((preNZoom-1.4)/0.62,0),1); // upper = 2.25
  nzoom = pow(10,preNZoom);
  pushMatrix();
  translate(NZOOM_X,NZOOM_Y);
  scale(nzoom);
  translate(-NZOOM_X,-NZOOM_Y);
  
  background(255);
  
  float zoomScale = getZoomScale();
  setcurrentWeek();
  
  drawLines(zoomScale);
  drawGround();
  float x = MAX_X+BAR_W*BOX_SIZE;
  translate(x,MAX_Y);
  scale(zoomScale);
  translate(-x,-MAX_Y);
  
  drawPillars(zoomScale);
  drawLabels(zoomScale);
  
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  
  if(frames < ZOOM_IN_AT){
    frames+=SPEED_MULTIPLIER;
  }else{
    nzFrames+=SPEED_MULTIPLIER;
  }
  popMatrix();
}
float getZoomScale(){
  if(currentWeekRem >= TIME_DIV_C){
    float start = zoomScales[currentWeekInt];
    float next = zoomScales[min(currentWeekInt+1,WEEK_COUNT-1)];
    float prog = cosInter(0,1,(currentWeekRem-TIME_DIV_C)/(1-TIME_DIV_C));
    return cosInter(start,next,prog);
  }else{
    return zoomScales[currentWeekInt];
  }
}
void drawLines(float zoomScale){
  for(int i = 0; i < COMP_COUNT-1; i++){
    Comparable com = comparables[i];
    drawLine(com.aboveName,com.name,com.unit,com.deaths,com.col,zoomScale);
  }
}
void drawLine(String astr, String str, String subtext, int count, color c,float zoomScale){
  float boxRows = ((float)count)/BAR_W;
  float y = MAX_Y-BOX_SIZE*boxRows*zoomScale;
  strokeWeight(3);
  stroke(c);
  line(0,y,width,y);
  textFont(fontMain,36);
  textAlign(RIGHT);
  fill(c);
  text(astr,width-13,y-44);
  text(str,width-13,y-8);
  text(commafy(count)+" "+subtext,width-15,y+35);
}
void drawGround(){
  fill(0);
  noStroke();
  rect(0,MAX_Y,width,height-MAX_Y);
}
void drawPillars(float zoomScale){
  for(int week = 0; week <= currentWeekInt; week++){
    float x = weekToX(week);
    pushMatrix();
    translate(x,MAX_Y);
    drawPillar(week,zoomScale);
    popMatrix();
  }
}
void drawLabels(float zoomScale){
  for(int week = 0; week <= WEEK_COUNT+3; week++){
    float x = weekToX(week);
    pushMatrix();
    translate(x,MAX_Y);
    drawLabel(week, zoomScale);
    popMatrix();
  }
}
void drawPillar(int week, float zoomScale){
  noStroke();
  int newDeaths = totals[week];
  float prog = (currentWeekRem-TIME_DIV_A)/(TIME_DIV_B-TIME_DIV_A);
  prog = min(max(prog,0),1);
  
  if(currentWeekRem > TIME_DIV_B || week < currentWeekInt){
    float labelProg = (currentWeekRem-TIME_DIV_B)/(TIME_DIV_C-TIME_DIV_B);
    float barHeight = BOX_SIZE*ceil(newDeaths/BAR_W);
    float scale = max(1,1/zoomScale);
    if(newDeaths < 2000){
      scale = min(2.5,scale);
    }
    if(week == currentWeekInt){
      scale *= cosInter(0,1,labelProg);
    }
    fill(0);
    textAlign(RIGHT);
    pushMatrix();
    translate(BAR_W*BOX_SIZE,-barHeight-4);
    scale(scale);
    String str = commafy(newDeaths)+" x";
    text(str,-60,-16);
    image(gravestone,-55,-55,55,55);
    popMatrix();
  }
  
  PGraphics flagCanvas = null;
  int countryOn = 0;
  for(int w = 0; w < newDeaths; w++){
    while(countries.get(countryOn).startEnd[week][1] <= w){
      countryOn++;
      flagCanvas = null;
    }
    Country coun = countries.get(countryOn);
    int bx = (BAR_W-1)-w%BAR_W;
    int by = w/BAR_W;
    color c = color(50,50,50);
    PImage fl = coun.flag;
    if(fl != null){
      int firstFullLine = ceil(((float)coun.startEnd[week][0])/BAR_W);
      int lastFullLine = floor(((float)coun.startEnd[week][1])/BAR_W)-1;
      int lineHeight = lastFullLine-firstFullLine+1;
      if(lineHeight >= 1){
        if(flagCanvas == null){
          flagCanvas = createGraphics(BAR_W,lineHeight);
          flagCanvas.beginDraw();
          flagCanvas.background(c);
          int imgH = lineHeight;
          int imgW = BAR_W;//(int)min(((float)imgH/fl.height)*fl.width,BAR_W);
          flagCanvas.image(fl,(int)(((float)BAR_W-imgW)/2),0,imgW,imgH);
          flagCanvas.endDraw();
        }
        if(by < firstFullLine){
          c = cap(fl.get((int)((bx+0.5)/BAR_W*(fl.width)),fl.height-1));
        }else if(by > lastFullLine){
          c = cap(fl.get((int)((bx+0.5)/BAR_W*(fl.width)),0));
        }else{
          c = cap(flagCanvas.get(bx,lineHeight-1-(by-firstFullLine)));
        }
      }else{
        c = cap(fl.get(fl.width/2,fl.height/2));
      }
    }
    if((bx+by)%2 == 0){
      c = darken(c);
    }
    fill(c);
    float appY = -BOX_SIZE-by*BOX_SIZE;
    float appH = BOX_SIZE;
    float noiseFactor = 2+0.5*min(BAR_W*6,0.1*min(w,newDeaths-1-w));
    float noisy = noise(w*100,week*100)*noiseFactor;
    float preMTTL = ((w+noisy)+1)/(newDeaths+2);
    preMTTL = min(max(preMTTL,0),1);
    float myTimeToLand = middlify(preMTTL)*(TIME_DIV_B-TIME_DIV_A)+TIME_DIV_A;
    if(newDeaths == 1){
      myTimeToLand = 0.4;
    }
    if(currentWeekRem >= myTimeToLand || week < currentWeekInt){
    }else if(currentWeekRem >= myTimeToLand-TIME_DIV_A){
      float fac = (myTimeToLand-currentWeekRem)/TIME_DIV_A;
      float myzs = MAX_Y/zoomScale;
      float frac = (myzs+BOX_SIZE*3)/myzs;
      float riseY = (1-pow(1-fac,2))*myzs*frac;
      appY -= riseY;
      appH += min(riseY,BOX_SIZE*(2-fac));
      appH = min(appH, BOX_SIZE*2.2);
      if(newDeaths > 2000){
        appH = min(appH, BOX_SIZE);
      }
    }else{
      continue;
    }
    rect(bx*BOX_SIZE,appY,BOX_SIZE,appH);
    
    if(textAlpha >= 1 && week == 13 && w < EPITAPH_COUNT && coun.name.equals("us") && SHOW_EPITAPHS){
      //fill(0,255,0);
      //rect(bx*BOX_SIZE,appY,BOX_SIZE,appH);
      PGraphics epi = createGraphics(200,200);
      epi.beginDraw();
      epi.textAlign(CENTER);
      epi.textFont(fontMain,36);
      epi.fill(0);
      if(max(red(c),green(c),blue(c)) < 128){
        epi.fill(255);
      }
      epi.text(epitaphs[w][0],100,70);
      epi.text(epitaphs[w][1],100,115);
      epi.text(epitaphs[w][2],100,160);
      epi.endDraw();
      tint(255,255,255,textAlpha);
      image(epi,bx*BOX_SIZE,appY,BOX_SIZE,appH);
      noTint();
    }
  }
}
void drawLabel(int week, float zoomScale){
  textFont(fontMain,36);
  textAlign(CENTER);
  fill(255);
  
  pushMatrix();
  translate(BOX_SIZE*BAR_W/2,0);
  
  float thisOne = 1;
  float nextOne = 1;
  if(week == currentWeekInt){
    thisOne = max(1,MAX_ZOOM/zoomScale);
  }
  if(week == currentWeekInt+1){
    nextOne = max(1,MAX_ZOOM/zoomScale);
  }
  float prog = cosInter(0,1,(currentWeekRem-TIME_DIV_C)/(1-TIME_DIV_C));
  float sf = lerp(thisOne,nextOne,prog);
  scale(sf);
  text(weekToDateStr(week),0,45);
  popMatrix();
}
float weekToX(int week){
  float relativeDay = week-currentWeekInt;
  if(currentWeekRem > TIME_DIV_C){
    relativeDay -= cosInter(0,1,(currentWeekRem-TIME_DIV_C)/(1-TIME_DIV_C));
  }
  return round(MAX_X+relativeDay*BAR_DIST);
}
float cosInter(float a, float b, float x){
  float xProg = 0;
  if(x < 0){
    xProg = 0;
  }else if(x >= 1){
    xProg = 1;
  }else{
    xProg = 0.5-0.5*cos(x*PI);
  }
  return a+(b-a)*xProg;
}
void setcurrentWeek(){
  currentWeek = frames/FRAMES_PER_WEEK;
  currentWeekInt = (int)currentWeek;
  currentWeekRem = currentWeek%1.0;
}
String flagFileize(String s){
  return capitalize(s).replace(" ","-");
}
String capitalize(String preS){
  String upperS = preS.toUpperCase();
  if(upperS.equals("US")){
    return "USA";
  }else if(upperS.equals("UK")){
    return upperS;
  }
  String s = preS.replace("-"," ");
  String result = "";
  for(int i = 0; i < s.length(); i++){
    if(i < s.length()-4 && s.substring(i,i+4).equals("and ") ||
    i < s.length()-3 && s.substring(i,i+3).equals("of ")){
      result = result+s.charAt(i);
    }else if(i == 0 || (i >= 1 && s.charAt(i-1) == ' ')){
      result = result+s.toUpperCase().charAt(i);
    }else{
      result = result+s.charAt(i);
    }
  }
  return result;
}
String fix(String s){
  if(trueCountries.containsKey(s)){
    return trueCountries.get(s);
  }
  return s;
}
int getIndexOf(String str){
  return getIndexOf(str,0,countries.size()-1);
}
int getIndexOf(String str, int s, int e){
  if(s > e){
    return -1-s;
  }
  int mid = (s+e)/2;
  String other = countries.get(mid).name;
  int comp = str.compareTo(other);
  if(comp > 0){
    return getIndexOf(str,s,mid-1);
  }else if(comp < 0){
    return getIndexOf(str,mid+1,e);
  }else{
    return mid;
  }
}
float middlify(float x){
  float ex = 0.2;
  if(x < 0.5){
    return (float)Math.max(Math.pow(x,ex)/Math.pow(0.5,ex),0.0)*0.5;
  }else{
    return 1-(float)Math.min(Math.pow(1-x,ex)/Math.pow(0.5,ex),1)*0.5;
  }
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
double dlerp(double a, double b, double x){
  return a+(b-a)*x;
}
color darken(color c){
  float r = red(c);
  float g = green(c);
  float b = blue(c);
  float f = 0.75;
  float s = 20;
  return color(r*f-s,g*f-s,b*f-s);
}
color cap(color c){
  float r = min(220,red(c));
  float g = min(220,green(c));
  float b = min(220,blue(c));
  return color(r,g,b);
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

int dateToDays(String s){
  int year = Integer.parseInt(s.substring(0,4))-1900;
  int month = Integer.parseInt(s.substring(5,7))-1;
  int date = Integer.parseInt(s.substring(8,10));
  Date d1 = new Date(year, month, date, 6, 6, 6);
  int days = (int)(d1.getTime()/86400000L);
  return days;
}

String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
String dayToDateStr(float daysF){
  int days = (int)daysF+START_DATE+1;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  return monthNames[month-1]+" "+date;
}
String weekToDateStr(float weeksF){
  String startS = dayToDateStr(weeksF*DIW);
  String endS = dayToDateStr(weeksF*DIW+DIW-1);
  if(startS.substring(0,2).equals(endS.substring(0,2))){
    return startS+" - "+endS.substring(4,endS.length());
  }else{
    return startS+" - "+endS;
  }
}
