import java.util.Date;
import com.hamoid.*;
String VIDEO_FILE_NAME = "MASK_county_test.mp4";
boolean COUNTY_MODE = false; // if true, it'll plot county dots. If false, it'll plot state dots.
boolean SAVE_VIDEO = false;
float DAY_SPEED = 0.136; // higher numbers = faster

int START_DATE = 18262;
int DAY_LEN = 366+8;
ArrayList<County> counties = new ArrayList<County>(0);
int COUNTY_COUNT;

float currentDay = 0;
float MASK_START = COUNTY_MODE ? 0.3 : 0.5;

float X_MIN = 160;
float X_MAX = 1860;
float Y_MIN = 230;
float Y_MAX = 950;
float X_W = X_MAX-X_MIN;
float Y_H = Y_MAX-Y_MIN;

PFont font;
PFont titleFont;
PImage background;
PImage stateShapes;
String[] newsByDay;
float[] maxes = new float[DAY_LEN];
Trendline[] trend = new Trendline[DAY_LEN];
VideoExport videoExport;

void setup(){
  background = loadImage("background.png");
  stateShapes = loadImage("stateShapes.jpg");
  font = loadFont("Jygquip1-80.vlw");
  titleFont = loadFont("GothamNarrow-Black-120.vlw");
  
  String[] data;
  String[] trendlineData;
  if(COUNTY_MODE){
    data = loadStrings("covid19_12_county_data.csv");
    trendlineData = loadStrings("covid19_12_county_trendline.csv");
  }else{
    data = loadStrings("covid19_12_state_data.csv");
    trendlineData = loadStrings("covid19_12_state_trendline.csv");
  }
  for(int d = 0; d < DAY_LEN; d++){
    trend[d] = new Trendline(trendlineData[d]);
    maxes[d] = 560;
  }
  COUNTY_COUNT = data.length;
  for(int c = 0; c < COUNTY_COUNT; c++){
      County newC = new County(data[c],c);
      int index = binSea(newC.pop,0,counties.size()-1);
      counties.add(index,newC);
  }
  
  
  
  newsByDay = loadStrings("compactNews.tsv");
  size(1920,1080);
  ellipseMode(RADIUS);
  noStroke();
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILE_NAME);
    videoExport.startMovie();
  }
}
void draw(){
  //scale(0.5);
  //fill(255,0,255);
  //rect(width,0,width,height*2);
  //rect(height,0,width*2,height);
  
  image(background,0,0);
  drawHoriz();
  drawVert();
  drawTrendline();
  drawBubbles();
  drawDate();
  currentDay += DAY_SPEED;
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  if(currentDay >= DAY_LEN){
    if(SAVE_VIDEO){
      videoExport.endMovie();
    }
    exit();
  }
}
int binSea(int pop, int beg, int end){
  if(beg > end){
    return beg;
  }
  int mid = (beg+end)/2;
  float val = counties.get(mid).pop;
  if(pop < val){
    return binSea(pop,mid+1,end);
  }else if(pop > val){
    return binSea(pop,beg,mid-1);
  }else{
    return mid;
  }
}
void drawHoriz(){
  for(int i = 0; i <= 10; i++){
    float mask = 0.1*i;
    float x = maskToX(mask);
    pushMatrix();
    translate(x,0);
    fill(255,255,255,92);
    rect(-2,0,4,Y_MAX);
    fill(255,255,255,180);
    textAlign(CENTER);
    textFont(font,40);
    text((i*10)+"%",0,Y_MAX+53);
    popMatrix();
  }
  float X_CENTER = (X_MAX+X_MIN)/2;
  text("Mask-wearers (Responded \"Frequently\" or \"Always\")",X_CENTER,Y_MAX+100);
}
void drawVert(){
  int INC = 200;
  if(COUNTY_MODE){
    INC = 500;
  }
  for(int cases = 0; cases <= 4000; cases+=INC){
    float y = casesToY(cases);
    pushMatrix();
    translate(0,y);
    fill(255,255,255,92);
    rect(X_MIN,-2,X_W,4);
    float alpha = 180*min(max((y-136)/43,0),1);
    fill(255,255,255,alpha);
    textAlign(RIGHT);
    textFont(font,40);
    float yee = 17;
    if(cases == 0) yee = -3;
    text(commafy(cases),X_MIN-10,yee);
    popMatrix();
  }
  pushMatrix();
  float Y_CENTER = (Y_MAX+Y_MIN)/2;
  translate(35,Y_CENTER);
  rotate(-PI/2);
  textAlign(CENTER);
  fill(255,255,255,180);
  text("New COVID-19 cases per day per million",0,16);
  popMatrix();
}
void drawTrendline(){
  float slope = getTrendStat(0,currentDay);
  float intercept = getTrendStat(1,currentDay);
  float r = getTrendStat(2,currentDay);
  float p = getTrendStat(3,currentDay);
  stroke(255,255,0);
  strokeWeight(4);

  int DASH_COUNT = 23;
  for(int dash = 0; dash < DASH_COUNT; dash++){
    float dash_MS = MASK_START+(1-MASK_START)*(((float)dash)/DASH_COUNT);
    float dash_ME = MASK_START+(1-MASK_START)*(((float)dash+0.5)/DASH_COUNT);
    float dash_CS = intercept+slope*dash_MS;
    float dash_CE = intercept+slope*dash_ME;
    float x1 = maskToX(dash_MS);
    float y1 = casesToY(dash_CS);
    float x2 = maskToX(dash_ME);
    float y2 = casesToY(dash_CE);
    line(x1,y1,x2,y2);
    if(dash == 0){
      fill(255,255,0);
      textFont(font,32);
      textAlign(LEFT);
      
      float XL = x1+10;
      float OFFSET = min(y1-20,Y_MAX-13);
      text("r = "+nf(r,0,3),XL,OFFSET-76);
      text("r   = "+nf(r*r,0,3),XL,OFFSET-38);
      text("p = "+nf(p,0,3),XL,OFFSET);
      textFont(font,22);
      text("2",XL+12,OFFSET-51);
    }
  }
  noStroke();
}
void drawDate(){
  fill(255);
  String str = daysToDate(currentDay);
  textAlign(CENTER);
  textFont(titleFont,120);
  text(str,width/2,120);
  String news = newsByDay[(int)currentDay].split("\t")[1];
  if(news.charAt(news.length()-1) == '.'){
    news += " ";
  }else{
    news += ". ";
  }
  textFont(font,40);
  textAlign(RIGHT);
  multiLineText(news,width-30,59,552);
  
  String typeS = "states";
  if(COUNTY_MODE){
    typeS = "counties";
  }
  textAlign(LEFT);
  text("Does wearing masks correlate with",30,59);
  text("new COVID-19 cases? (US "+typeS+")",30,99);
  textFont(font,25);
  text("Video by Cary Huang (youtube.com/1abacaba1)",30,139);
}
void multiLineText(String str, float x, float y, float w){
  int lastOKStopper = 0;
  for(int c = 0; c < str.length(); c++){
    if(str.charAt(c) == ' '){
      float tw = textWidth(str.substring(0,c));
      if(tw < w){
        lastOKStopper = c;
      }else{
        break;
      }
    }
  }
  text(str.substring(0,lastOKStopper),x,y);
  if(lastOKStopper < str.length()-1){
    multiLineText(str.substring(lastOKStopper,str.length()),x,y+40,w);
  }
}
void drawBubbles(){
  for(int c = 0; c < COUNTY_COUNT; c++){
    County co = counties.get(c);
    float casesNow = co.getCases(currentDay);
    float x = maskToX(co.mask);
    float y = casesToY(casesNow);
    float r = popToR(co.pop);
    pushMatrix();
    translate(x,y);
    scale(r/100,r/100);
    
    fill(co.col);
    ellipse(0,0,100,100);
    tint(co.col);
    if(!COUNTY_MODE){
      image(co.stateImage,-70.5,-70.5,141,141);
    }
    noTint();
    
    if(!COUNTY_MODE){
      textFont(font,154);
      fill(co.col);
      textAlign(CENTER);
      text(co.name,0,-139);
    }else if(co.pop >= 50000){
      float fs = 630/pow(r,0.5);
      textFont(font,fs);
      fill(co.col);
      textAlign(CENTER);
      text(co.name,0,-fs*0.9);
    }
    popMatrix();
  }
}
float maskToX(float mask){
  return X_MIN + X_W*((mask-MASK_START)/(1-MASK_START));
}
float casesToY(float cases){
  return Y_MAX - Y_H*cases/getMaxes(currentDay);
}
float popToR(float pop){
  if(COUNTY_MODE){
    return pow(pop,0.24)*0.26;
  }else{
    return pow(pop,0.18)*1.0;
  }
}

String daysToDate(float daysF){
  String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};

  int days = (int)daysF+START_DATE+1;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  return monthNames[month-1]+" "+date+", "+year;
}

float getMaxes(float day){
  int dayInt = (int)day;
  float before = maxes[dayInt];
  float after = maxes[min(dayInt+1,DAY_LEN-1)];
  float prog = day%1.0;
  float val = before+(after-before)*prog;
  if(COUNTY_MODE){
    return 1900;
  }else{
    return val;
  }
}
float getTrendStat(int stat, float day){
  int dayInt = (int)day;
  float before = trend[dayInt].stats[stat];
  float after = trend[min(dayInt+1,DAY_LEN-1)].stats[stat];
  float prog = day%1.0;
  return before+(after-before)*prog;
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
