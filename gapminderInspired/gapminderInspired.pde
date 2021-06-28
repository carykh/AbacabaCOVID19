import java.util.*; 
import java.io.File;
import java.util.Date;
import java.text.*;
import com.hamoid.*;

String DATA_LOCATION = "countryData/fullData_country_2021-06-27.tsv";
String VIDEO_FILE_NAME = "OUTPUTTED_VIDEO.mp4";
double daySpeed = 0.5;

/*
// ************** US STATE SETTINGS ***************

String[] CONTINENT_NAMES = {"pa","ro","sw","mw","se","ne"};
color[] CONTINENT_COLORS = {color(0,50,255),color(140,0,255),
color(180,88,0),color(140,133,0),color(230,0,0),color(0,135,0)};
String[] CONTINENT_LNAMES = {"Pacific", "Rocky Mountains",
"Southwest", "Midwest", "Southeast", "Northeast"};
int COUNTRY_COUNT = 51;
String REGIONALS_LOCATION = "../usRegions.tsv";
float BUBBLE_SIZE_MULTIPLIER = 0.0038;
String DESCRIPTOR = "United States";
// **********************************************
*/


//  *************** WORLDWIDE SETTINGS ***************

String[] CONTINENT_NAMES = {"na","sa","e","af","as","oc"};
color[] CONTINENT_COLORS = {color(180,88,0),color(140,0,255),
color(0,135,0),color(140,133,0),color(0,50,255),color(230,0,0)};
String[] CONTINENT_LNAMES = {"North America", "South America",
"Europe", "Africa", "Asia", "Oceania"};
int COUNTRY_COUNT = 216;
String REGIONALS_LOCATION = "continents.tsv";
float BUBBLE_SIZE_MULTIPLIER = 0.001;
String DESCRIPTOR = "Worldwide";
// **********************************************

int DAY_LEN = -1; // Will be set to the number of days until the final date on the worldometers pages. (Set near the start of void setup().)
Country[] countries = new Country[COUNTRY_COUNT];
String[] data;
String[] continentData;
int START_DATE = 18262;

float X_MIN = 100;
float X_MAX = 1860;
float X_W = X_MAX-X_MIN;
float Y_MIN = 0;
float Y_MAX = 1000;
float Y_H = Y_MAX-Y_MIN;

PFont fontSmall;
PFont fontBig;

PImage coronavirusImage;

double[] casesWorld;
double[] deathsWorld;
double[] casesTotal;
double[] deathsTotal;

String vidCountry = "";
int vidC = -1;
VideoExport videoExport;

double currentDay = 0;

void setup(){
  if(vidCountry.length() >= 1){
    int IOP = vidCountry.indexOf(".");
    VIDEO_FILE_NAME = VIDEO_FILE_NAME.substring(0,IOP)+"_"+vidCountry+VIDEO_FILE_NAME.substring(IOP,VIDEO_FILE_NAME.length());
  }
  ellipseMode(RADIUS);
  coronavirusImage = loadImage("coronavirus.png");
  fontSmall = loadFont("Jygquip1-24.vlw");
  fontBig = loadFont("Jygquip1-80.vlw");
  data = loadStrings(DATA_LOCATION);
  continentData = loadStrings(REGIONALS_LOCATION);
  DAY_LEN = getDayLen(data);
  
  casesWorld = new double[DAY_LEN];
  deathsWorld = new double[DAY_LEN];
  casesTotal = new double[DAY_LEN];
  deathsTotal = new double[DAY_LEN];
  for(int d = 0; d < DAY_LEN; d++){
    casesWorld[d] = 0;
    deathsWorld[d] = 0;
    casesTotal[d] = 0;
    deathsTotal[d] = 0;
  }
  for(int c = 0; c < COUNTRY_COUNT; c++){
    countries[c] = new Country(data[c],continentData[c]);
    if(vidCountry.equals(countries[c].name)){
      vidC = c;
    }
  }
  for(int d = 1; d < DAY_LEN; d++){
    casesTotal[d] = casesTotal[d-1]+casesWorld[d];
    deathsTotal[d] = deathsTotal[d-1]+deathsWorld[d];
  }
  
  size(1920,1080);
  smooth();
  noStroke();
  
  videoExport = new VideoExport(this, VIDEO_FILE_NAME);
  videoExport.startMovie();
}
void draw(){
  background(255);
  drawGrid();
  drawExternals();
  for(int c = COUNTRY_COUNT-1; c >= 0; c--){
    countries[c].drawCountry(currentDay);
  }
  drawTrail();
  drawDate();
  drawKey();
  videoExport.saveFrame();
  if(currentDay >= DAY_LEN+10){
    videoExport.endMovie();
    exit();
  }
  currentDay += daySpeed;
}
int getDayLen(String[] data){
  String[] parts = data[0].split("\t");
  return commaSeparate(parts[2]).length;
}
int[] commaSeparate(String s){
    String[] parts = s.split(",");
    int[] results = new int[parts.length];
    for(int i = 0; i < parts.length; i++){
      results[i] = Integer.parseInt(parts[i]);
    }
    return results;
  }
void drawExternals(){
  drawExternal("Influenza",true,0.00036287761d,0.000000157d);
  drawExternal("2014 Ebola",true,0.0000071d,0.0000028d);
  drawExternal("2009 Swine Flu",false,0.0002935d,0.000000083d);
  drawExternal("1918 Spanish Flu",false,0.00065d,0.00005d);
}
void drawTrail(){
  colorMode(HSB,1.0);
  strokeWeight(5);
  if(vidC >= 0){
    Country co = countries[vidC];
    for(int d = 0; d < Math.ceil(currentDay); d++){
      float xs = casesToX(co.getCPC(d));
      float ys = deathsToY(co.getDPC(d));
      float xe = casesToX(co.getCPC(d+1));
      float ye = deathsToY(co.getDPC(d+1));
      
      float fac = 1;
      if(d == Math.floor(currentDay)){
        fac = (float)(currentDay%1.0);
      }
      float xp = xs+(xe-xs)*fac;
      float yp = ys+(ye-ys)*fac;
      
      float cycle = (float)((d*0.02+DAY_LEN-currentDay*0.06)%1.0);
      stroke(cycle,1,0.6);
      line(xs,ys,xp,yp);
      
      String dateStr = daysToDate(d,true);
      int dayStr = Integer.parseInt(dateStr.substring(9,dateStr.length()));
      if((dayStr == 1 || dayStr == 16) && d < DAY_LEN){
        noStroke();
        fill(cycle,1,0.6);
        ellipse(xs,ys,7,7);
        textAlign(LEFT);
        textFont(fontSmall,24);
        text(dateStr.substring(5,dateStr.length()),xs+9,ys+19);
      }
    }
  }
  noStroke();
  colorMode(RGB,255);
}
void drawKey(){
  noStroke();
  textAlign(RIGHT);
  textFont(fontSmall,24);
  for(int c = 0; c < 6; c++){
    pushMatrix();
    translate(width-70,Y_MAX-255+40*c);
    fill(CONTINENT_COLORS[c]);
    rect(0,0,50,33);
    text(CONTINENT_LNAMES[c],-10,26);
    popMatrix();
  }
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
void drawExternal(String str,boolean onTop,double caseR, double deathR){
  float x = casesToX(caseR);
  float y = deathsToY(deathR);
  noFill();
  strokeWeight(3);
  //colorMode(HSB,1);
  
  double S = 0.04/daySpeed;
  double fac = (currentDay*S)%1.0;
  
  for(int l = 0; l < 2; l++){
    float r = (float)(30*((l+fac)/2.0));
    float a = (float)(2-l-fac);
    //stroke((float)fac,1,0.5,a);
    stroke(0,0,0,a*128);
    ellipse(x,y,r,r);
  }
  textAlign(CENTER);
  textFont(fontSmall,24);
  fill(0,0,0,128);
  if(onTop){
    text(str,x,y-29);
  }else{
    text(str,x,y+35);
  }
  noStroke();
}
void drawGrid(){
  double BILLION = 1000000000;
  int[] units = {0,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000,2000000};
  for(int u = 0; u < units.length; u++){
    double unit = ((double)units[u])/BILLION;
    String name = namify((int)units[u]);
    drawHoriz(unit,name);
    drawVert(unit,name);
  }
  for(int pu = 7; pu <= 12; pu++){
    int u = pu;
    if(pu == 7){
      u = 5;
    }else if(pu == 12){
      u = 14;
    }
    double prop = ((double)units[u])/100000;
    drawDiag(prop, true);//(u%3 == 2));
  }
}
String namify(int e){
  if(e < 10){
    return "0.00"+e;
  }else if(e < 100){
    return "0.0"+(e/10);
  }else if(e < 1000){
    return "0."+(e/100);
  }else if(e < 1000000){
    return (e/1000)+"";
  }else if(e < 1000000000){
    return (e/1000000)+"K";
  }else{
    return (e/1000000000)+"M";
  }
}
void drawDiag(double u, boolean highlight){
  strokeWeight(3);
  if(highlight){
    stroke(255,0,0,120);
    fill(230,0,0,177);
  }else{
    stroke(0,0,0,120);
    fill(0,0,0,177);
  }
  double prevF = -25.25;
  double LAST = -10.0;
  if(u <= 0.0011){
    LAST = -12.75;
  }
  if(Math.abs(u-0.05) < 0.0001){ // 5% fatality tag can't be right at the edge of the screen
    LAST = -10.75;
  }
  if(Math.abs(u-0.01) < 0.0001){ // 1% fatality tag can't be right at the edge of the screen
    LAST = -10.50;
  }
  for(double f = -25.0; f <= LAST; f += 0.25){
    double val = Math.exp(f);
    double prevVal = Math.exp(prevF);
    float x1 = casesToX(val/u);
    float y1 = deathsToY(val);
    float x2 = casesToX(prevVal/u);
    float y2 = deathsToY(prevVal);
    line(x1,y1,x2,y2);
    
    if(f == LAST){
      textAlign(24);
      textAlign(CENTER);
      String str = (int)Math.round(u*100)+"";
      if(u <= 0.0011){
        str = "0.1";
      }
      text(str+"%",x1,y1-33);
      text("CFR",x1,y1-9);
    }
    
    prevF = f;
  }
  noStroke();
}
void drawHoriz(double u, String name){
  float y = deathsToY(u);
  if(y >= Y_MIN && y <= Y_MAX){
    fill(180);
    rect(X_MIN,y-2,X_W,4);
    fill(70);
    textAlign(RIGHT);
    textFont(fontSmall, 24);
    text(name,X_MIN-5,y+8);
  }
}
void drawVert(double u, String name){
  float x = casesToX(u);
  if(x >= X_MIN && x <= X_MAX){
    fill(180);
    rect(x-2,Y_MIN,4,Y_H);
    fill(70);
    textAlign(CENTER);
    textFont(fontSmall, 24);
    text(name,x,Y_MAX+26);
  }
}
void drawDate(){
  fill(0);
  textFont(fontBig,80);
  textAlign(LEFT);
  
  text(daysToDate((float)Math.min(currentDay,DAY_LEN-1),true),670,80);
  image(coronavirusImage,230,250,220,220);
  
  
  textFont(fontBig,63);
  text("COVID-19 cases and",150,62);
  text("deaths per capita",150,122);
  textFont(fontBig,30);
  text("Video created by Cary Huang at",150,172);
  text("youtube.com/1abacaba1",150,206);
  
  
  text(DESCRIPTOR+" cases: "+commafy(Math.round(getAV(currentDay,casesTotal,1))),673,137);
  text(DESCRIPTOR+" deaths: "+commafy(Math.round(getAV(currentDay,deathsTotal,1))),673,171);
  
  fill(70);
  textFont(fontBig,40);
  textAlign(CENTER);
  text("New COVID-19 cases per million people per day",X_MIN+X_W*0.5,Y_MAX+62);
  
  pushMatrix();
  rotate(-PI/2);
  text("New COVID-19 deaths per million people per day",-Y_MIN-Y_H*0.5,X_MIN-60);
  popMatrix();
  
  
  
}
int bound(int d){
  return min(max(d,0),DAY_LEN-1);
}
float casesToX(double c){
  double a = -17.7;
  double b = -6;
  
  double p = (Math.log(c+0.00000003d)-a)/(b-a);
  return (float)(X_MIN+X_W*p);
}
float deathsToY(double c){
  double a = -18.5;
  double b = -9.48;
  double p = (Math.log(c+0.00000001d)-a)/(b-a);
  return (float)(Y_MAX-Y_H*p);
}
float popToR(int p){
  return (float)(sqrt(p)*BUBBLE_SIZE_MULTIPLIER);
}
String capitalize(String s){
  String st = s.replace("-"," ");
  if(s.equals("us")){
    st = "united states";
  }else if(s.equals("uk")){
    st = "united kingdom";
  }else if(s.equals("viet-nam")){
    st = "vietnam";
  }else if(s.equals("china-hong-kong-sar")){
    st = "hong kong";
  }else if(s.equals("china-macau-sar")){
    st = "macau";
  }
  String result = "";
  for(int i = 0; i < st.length(); i++){
    String ch = st.substring(i,i+1);
    if(i == 0 || (i >= 1 && st.charAt(i-1) == ' ')){
      ch = ch.toUpperCase();
    }
    result = result+ch;
  }
  return result;
}

String daysToDate(float daysF, boolean longForm){
  String[] monthNames = {"JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"};

  int days = (int)daysF+START_DATE+1;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  if(longForm){
    return year+" "+monthNames[month-1]+" "+date;
  }else{
    return year+"-"+nf(month,2,0)+"-"+nf(date,2,0);
  }
}
double[] smoothArray(int[] arr){
  int WINDOW = 7;
  double[] result = new double[DAY_LEN];
  for(int i = 0; i < DAY_LEN; i++){
    int windowStart = bound(i-WINDOW);
    int windowEnd = bound(i+WINDOW);
    double counter = 0;
    double summer = 0;
    for(int j = windowStart; j <= windowEnd; j++){
      double val = max(0,arr[j]);
      double weight = WINDOW-abs(j-i);
      counter += weight;
      summer += val*weight;
    }
    result[i] = summer/counter;
  }
  return result;
}
double getAV(double day, double[] arr, int div){
  int firstDay = bound((int)day);
  int nextDay = bound(firstDay+1);
  double rem = day%1.0;
  double firstValue = ((double)arr[firstDay])/div;
  double nextValue = ((double)arr[nextDay])/div;
  return firstValue+(nextValue-firstValue)*rem;
}
