import java.util.*; 
import com.hamoid.*;
boolean SAVE_VIDEO = true;
String VIDEO_FILENAME = "test3.mp4";
float FRAMES_PER_DAY = 6; // This variable changes the playback speed of the video
int DIS_COUNT = 11; // change to 10 to not include 2020-21 COVID-19, change to 11 to include 2020-21 COVID-19.
int FLAG_N = DIS_COUNT;
int VIS_SPOT = DIS_COUNT; // How many ranks of diseases to show on the right
int SPECIAL = 10; // which disease is the one we're focusing on?
int LAST_DAY_OF_TBA_GRAPH = 263;

VideoExport videoExport;


String[] data;


Disease[] diseases = new Disease[DIS_COUNT];
int MAX_LEN = 396;
int frames = 0;//10*140;//(int)(43.9*111);//40*80;
float currentDay = 0;
int currentDayInt = 0;
float currentDaySim = 0;
float currentDayRem = 0;
float currentDayApp = 0;
int LAST_DAY = 365+5; // extra buffer of 5 days at the end, to be safe

int[] SPECIALS = {10};
int ZOOM_LENGTH = 26;


color[] cols =  {
  color(255, 15, 84),color(255, 55, 70),color(255, 95, 56),
  color(255, 135, 42),color(255, 175, 28),color(255, 215, 14),
  color(255, 255, 0),color(0, 242, 255), color(110, 120, 255), 
  
  color(50, 200, 0), color(0, 242, 255),color(245, 122, 126),
  color(255, 255, 255), color(255, 255, 0)};
long[] maxes = new long[MAX_LEN];
long[] maxesActive = new long[MAX_LEN];
long[] units = {1L, 2L, 5L, 10L, 20L, 50L, 100L, 200L, 500L, 1000L, 2000L, 5000L, 10000L, 20000L, 50000L, 100000L, 200000L, 500000L, 1000000L, 2000000L, 5000000L, 10000000L, 20000000L, 50000000L, 100000000L, 200000000L, 500000000L, 
  1000000000L, 2000000000L, 5000000000L, 10000000000L, 20000000000L, 50000000000L, 100000000000L, 200000000000L, 500000000000L};

int[] timeUnits = {1,2,5,10,15,30,60,90,180,360};

int[] vertUnitChoice = new int[MAX_LEN];
int[] horizUnitChoice = new int[MAX_LEN];
int[] textUnitChoice = new int[MAX_LEN];
int[] imgChoice = new int[MAX_LEN];
PImage[] imgArray = new PImage[MAX_LEN];
float X_MIN = 158;
float X_MAX = 1340;
float Y_MIN = 150;
float Y_MAX = 950;
float ELLIPSE_R = 10;
float X_LABEL = (1920+X_MAX)*0.5;
float EPS = 0.002;
float WIDGET_H = 40;
float BWIDGET_H = 58;
float MIN_WIDGET_Y = 120;
boolean derive = false;
boolean expo = false;
float expoContinue = -1;//1.01;

int START_DATE = dateToDays("2019-10-01");
int END_LEN = 600;

PImage background;
PFont font;
PFont fontBig;
PFont squish;
PImage usFlag;

void setup() {
  usFlag = loadImage("../../_flags/flag-of-USA.png");
  if (derive) {
    X_MAX = 1800;
  }
  if (expoContinue >= 0) {
    Y_MIN = 200;
  }
  squish = loadFont("QuickTypeIICondensed-25.vlw");
  font = loadFont("Gotham-Medium-66.vlw");
  fontBig = loadFont("GothamNarrow-Black-120.vlw");
  background = loadImage("background1.png");
  data = loadStrings("totalData2021.csv");
  for (int day = 0; day < MAX_LEN; day++) {
    maxes[day] = 30;
    maxesActive[day] = 0;
    imgChoice[day] = 0;
    if(day >= 300){
      maxes[day] = 90000+(day-300)*100;
    }
  }
  for (int d = 0; d < DIS_COUNT; d++) {
    diseases[d] = new Disease(d, data[d]);
  }
  for (int day = 0; day < MAX_LEN; day++) {
    boolean[] taken = new boolean[VIS_SPOT];
    for (int d = 0; d < VIS_SPOT; d++) {
      taken[d] = false;
    }
    int[] list = new int[VIS_SPOT];
    for (int spot = 0; spot < VIS_SPOT; spot++) {
      list[spot] = -1;
      float record = 9999;
      int holder = -1;
      for (int d = 0; d < VIS_SPOT; d++) {
        float val = casesToY(diseases[d].cases[day], day);
        if (!taken[d] && val <= record && (d != SPECIAL || day < LAST_DAY+7 || expoContinue >= 0)) {
          record = val;
          holder = d;
        }
      }
      list[spot] = holder;
      if (holder >= 0) {
        taken[holder] = true;
      }
    }
    float cursor = 9999;
    for (int spot = VIS_SPOT-1; spot >= 0; spot--) {
      int d = list[spot];
      if (d >= 0) {
        float desired = casesToY(diseases[d].cases[day], day);
        desired = max(desired, 193+spot*WIDGET_H);
        float gap = WIDGET_H;
        if (diseases[d].cases[day] == maxesActive[day]) {
          gap = BWIDGET_H;
          desired += 40;
        }
        float truth = min(desired, cursor-gap);
        cursor = truth;
        diseases[d].labelY[day] = cursor;
        if (diseases[d].labelY[day] < MIN_WIDGET_Y) {
          diseases[d].labelY[day] = MIN_WIDGET_Y;
          diseases[list[1]].labelY[day] = MIN_WIDGET_Y+WIDGET_H;
        }
      }
    }
  }
  for (int day = 0; day < MAX_LEN; day++) {
    vertUnitChoice[day] = 0;
    while (units[vertUnitChoice[day]] < maxes[day]*0.17) {
      vertUnitChoice[day]++;
    }
    horizUnitChoice[day] = 0;
    while (timeUnits[horizUnitChoice[day]] < day*0.21) {
      horizUnitChoice[day]++;
    }
    textUnitChoice[day] = 1;
    while (textUnitChoice[day] < day*0.106) {
      textUnitChoice[day]++;
    }
  }
  size(1920, 1080);
  ellipseMode(RADIUS);
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}
void draw() {
  background(255);
  //scale(0.5);
  image(background, 0, 0);
  fill(0, 0, 0, 100);
  rect(0, 0, width, height);
  setDayVars();
  drawGridVert(currentDayApp);
  drawGridHoriz(currentDayApp);
  drawLines();
  drawTitles();

  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  if(currentDay >= LAST_DAY){
    if(SAVE_VIDEO){
      videoExport.endMovie();
    }
    exit();
  }
  frames++;
}
void setDayVars() {
  currentDay = min(frames/FRAMES_PER_DAY, END_LEN+0.99);
  currentDayInt = (int)currentDay;
  currentDaySim = currentDay%1.0;
  currentDayRem = snapInter(0, 1, currentDaySim);
  currentDayApp = currentDayInt+currentDayRem;
}
void drawTitles() {
  pushMatrix();
  translate(152, 0);
  textAlign(LEFT);
  String dateStr = dayToDateStr(currentDayInt-1, true);
  if (expoContinue >= 0) {
    fill(255);
    textFont(font, 60);
    text("Projection based on", 39, 100);
    text(nf((expoContinue-1)*100, 0, 1)+"% day-on-day growth", 39, 165);
    textFont(font, 30);
    fill(cols[1]);
    text("This is by "+dateStr+" (Day "+currentDayInt+").", 39, 220);
    fill(255, 255, 0);
    pushMatrix();
    translate(39, 275);
  } else if (derive) {
    pushMatrix();
    translate(39, 300);
    // translate(777,322);
  } else {
    fill(255);
    textFont(fontBig, 120);
    text(dateStr, 35, 235);
    textFont(font, 48);
    text("Death counts of flu seasons", 39, 70);
    text("(and others) by", 39, 120);
    text("in the United States", 39, 297);
    pushMatrix();
    translate(39, 322);
  }
  image(usFlag,0,0,204,120);
  fill(255,255,0);
  textFont(font, 30);
  text("Video by Cary Huang", 0, 165);
  text("a.k.a. @realCarykh", 0, 200);
  textFont(font, 24);
  text("youtube.com/1abacaba1", 0, 232);
  popMatrix();
  popMatrix();
}
void drawGridVert(float cday) {
  int c1 = vertUnitChoice[min(MAX_LEN-1,(int)cday)];
  int c2 = vertUnitChoice[min(MAX_LEN-1,(int)cday+1)];
  if (c1 != c2) {
    drawGridVertHelper(c1, cday, lerp(1, 0, cday%1.0));
    drawGridVertHelper(c2, cday, lerp(0, 1, cday%1.0));
  } else {
    drawGridVertHelper(c1, cday, 1.0);
  }
}
void drawGridHoriz(float cday) {
  int c1 = horizUnitChoice[min(MAX_LEN-1,(int)cday)];
  int c2 = horizUnitChoice[min(MAX_LEN-1,(int)cday+1)];
  if (c1 != c2) {
    drawGridHorizHelper(c1, cday, lerp(1, 0, cday%1.0));
    drawGridHorizHelper(c2, cday, lerp(0, 1, cday%1.0));
  } else {
    drawGridHorizHelper(c1, cday, 1.0);
  }
}
void drawGridVertHelper(int u, float cday, float alpha) {
  long unit = units[u];
  strokeWeight(4);
  stroke(155, 200, 255, 70*alpha);
  fill(155, 200, 255, 110*alpha);
  
  
  for (long v = 0; v < maxes[min(MAX_LEN-1,(int)cday+1)]*1.5; v += unit) {
    float lineY = casesToY(v, cday);
    line(X_MIN, lineY, X_MAX, lineY);
    textFont(font, 48);
    textAlign(RIGHT);
    text(keyify(v), X_MIN-17, lineY+16);
  }
}
void drawGridHorizHelper(int u, float cday, float alpha) {
  long unit = timeUnits[u];
  strokeWeight(4);
  stroke(155, 200, 255, 70*alpha);
  fill(155, 200, 255, 110*alpha);
  for(int d = 0; d < (int)cday+1; d++){
    String dayStr = dayToDateStr(d-1,false);
    String[] parts = dayStr.split("-");
    int month = Integer.parseInt(parts[1]);
    int day = Integer.parseInt(parts[2]);
    boolean doIt = false;
    if(unit < 30){
      if((day-1)%unit == 0 && (unit <= 2 || day < 30)){
        doIt = true;
      }
    }else{
      if(day == 1 && (month-1)%(unit/30) == 0){
        doIt = true;
      }
    }
    if(doIt){
      float lineX = dayToX(d, cday);
      line(lineX, -10, lineX, Y_MAX);
      textFont(font, 48);
      textAlign(CENTER);
      text(dayToDateStr(d-1,true), lineX, Y_MAX+58);
    }
  }
}
boolean isSpecial(int d){
  for(int i = 0; i < SPECIALS.length; i++){
    if(d == SPECIALS[i]){
      return true;
    }
  }
  return false;
}
void drawLines() {
  for (int d = 0; d < DIS_COUNT; d++) {
    strokeWeight(6);
    Disease di = diseases[d];
    int MAX_I = currentDayInt;
    if (isSpecial(d) && expoContinue < 0) {
      MAX_I = min(currentDayInt, LAST_DAY+3);
    }
    for (int day = 0; day <= MAX_I; day++) {
      float x1 = dayToX(day, currentDayApp);
      float y1 = casesToY(di.cases[day], currentDayApp);

      float x2 = dayToX(day+1, currentDayApp);
      float y2 = casesToY(di.cases[min(MAX_LEN-1,day+1)], currentDayApp);

      float xe = x2;
      float ye = y2;
      if (day == currentDayInt) {
        xe = lerp(x1, x2, currentDayRem);
        ye = lerp(y1, y2, currentDayRem);
      }
      boolean isFuture = (isSpecial(d) && day >= LAST_DAY_OF_TBA_GRAPH);
      if (!(isFuture && expoContinue < 0)) {
        if (isFuture) {
          if (day%2 == 0) {
            strokeWeight(4);
          } else {
            continue;
          }
        }
        if(d < FLAG_N){
          stroke(getCol(d));
          strokeWeight(6);
          line(x1, y1, xe, ye);
        }else{
          /*float alpha = 150*abs(currentDay%4-2);
          if(currentDay < LAST_DAY+8){
            alpha = 0;
          }*/
          float alpha = min(max((currentDay-(LAST_DAY_OF_TBA_GRAPH+4))/10,0),1)*160;
          stroke(getCol(d,alpha));
          strokeWeight(2);
          drawDottedLine(x1, y1, xe, ye,30,d);
        }
        noStroke();
        if(d < FLAG_N){
          int u1 = textUnitChoice[min(MAX_LEN-1,currentDayInt)];
          int u2 = textUnitChoice[min(MAX_LEN-1,currentDayInt+1)];
          boolean isMax = (di.cases[min(MAX_LEN-1,day+1)] == maxesActive[min(MAX_LEN-1,day+1)]);
  
          int base = -1;
          if (isSpecial(d)) {
            base = LAST_DAY_OF_TBA_GRAPH-1;
          }
          float preAlpha = ((day+u1*100-base)%u1 == 0 && isMax) ? 1 : 0;
          float postAlpha = ((day+u2*100-base)%u2 == 0 && isMax) ? 1 : 0;
          if(day >= LAST_DAY){
            preAlpha = ((day+u1*100-base)%(2*u1) == 0 && isMax) ? 1 : 0;
            postAlpha = ((day+u2*100-base)%(2*u2) == 0 && isMax) ? 1 : 0;
          }
  
          float alpha = lerp(preAlpha, postAlpha, currentDayRem);
          drawEllipse(day+1, di.cases[min(MAX_LEN-1,day+1)], xe, ye, d, alpha);
          if (day == 0) {
            drawEllipse(day, di.cases[0], x1, y1, d, 1);
          }
        }
      }
    }
    if (!(isSpecial(d) && currentDayInt >= LAST_DAY_OF_TBA_GRAPH+5
    && expoContinue < 0) && !derive && d < FLAG_N) {
      float yPre = di.labelY[min(MAX_LEN-1,currentDayInt)];
      float yPost = di.labelY[min(MAX_LEN-1,currentDayInt+1)];
      float ye = lerp(yPre, yPost, currentDayRem);
      pushMatrix();
      translate(X_MAX+20, ye);
      float sc = 1;
      if (isSpecial(d) && currentDayInt == LAST_DAY_OF_TBA_GRAPH+4) {
        sc = min(max((1-currentDaySim)/0.35f, 0), 1);
      }
      scale(sc);
      PImage im = di.fixedLogo;
      int zaza = max(1, (int)(currentDay+0.5));
      boolean small = (di.cases[zaza] < maxesActive[zaza]);
      long cases = (long)lerp(di.cases[min(MAX_LEN-1,currentDayInt)],
           di.cases[min(MAX_LEN-1,currentDayInt+1)], currentDayRem);
      if (small) {
        image(im, 0, -18, 60, 36);
        textFont(font, 30);
        fill(getCol(d));
        textAlign(LEFT);
        String deaths = commafy(cases, true);
        text(di.name+": "+deaths, 70, 10);
      } else {
        image(im, 0, -126, 180, 108);
        fill(getCol(d));
        textFont(font, 66);
        textAlign(LEFT);
        text(di.nameSection(0), 193, -60);
        textFont(font, 30);
        text(di.nameSection(1), 193, -18);
        textFont(font, 38);
        text(commafy(cases, true)+" dead", 4, 23);
      }
      popMatrix();
    }
  }
}
void drawDottedLine(float x1, float y1, float xe, float ye, int RES, int d){
  int O = (int)(RES*((1.618033*d)%1.0));
  int start_x_int = (int)((x1-O)/RES)*RES+O;
  int end_x_int = (int)((xe-O)/RES)*RES+O;
  for(int x_int = start_x_int; x_int <= end_x_int; x_int += RES){
    if(x_int%(RES*2) < RES){
      float frac_start = min(max((x_int-x1)/(xe-x1),0),1);
      float frac_end = min(max((x_int-x1+30)/(xe-x1),0),1);
      float x_start = x1+(xe-x1)*frac_start;
      float y_start = y1+(ye-y1)*frac_start;
      float x_end = x1+(xe-x1)*frac_end;
      float y_end = y1+(ye-y1)*frac_end;
      if(x_end > x_start){
        line(x_start,y_start,x_end,y_end);
      }
    }
  }
}

color getCol(int d){
  if(d < FLAG_N){
    return cols[d];
  }else{
    return cols[d-FLAG_N];
  }
}
color getCol(int d, float a){
  color c = getCol(d);
  float newR = red(c);
  float newG = green(c);
  float newB = blue(c);
  return color(newR, newG, newB, a);
}
void drawEllipse(int day, long count, float x, float y, int d, float alpha) {
  pushMatrix();
  translate(x, y);
  float age = currentDay-day;
  float fac = min(max((currentDay-25)/50, 0), 1)*(1-alpha);
  float realR = lerp(ELLIPSE_R, 0, fac);

  if (age >= 0) {
    scale(-cos((age+EPS)*80)*pow(0.5, (age+EPS)*30)+1);
    textFont(font, 38);
    noStroke();
    if (realR > 0) {
      fill(getCol(d));
      ellipse(0, 0, realR, realR);
    }
    if (alpha > 0) {
      fill(red(getCol(d)), green(getCol(d)), blue(getCol(d)), alpha*255);
      textAlign(RIGHT);
      if (!derive) {
        if (d == SPECIAL && day == LAST_DAY && expoContinue < 0) {
          text(commafy(count, true), 0, -ELLIPSE_R-48);
          text("(TBD)", 0, -ELLIPSE_R-10);
        } else {
          text(commafy(count, true), 0, -ELLIPSE_R-10);
        }
      }
    }
  }
  popMatrix();
}
float snapInter(float a, float b, float x) {
  if (x < 0.5) {
    return lerp(a, b, pow(x, 3)/pow(0.5, 2));
  } else {
    return lerp(b, a, pow(1-x, 3)/pow(0.5, 2));
  }
}
float cosInter(float a, float b, float x) {
  float xProg = 0;
  if (x < 0) {
    xProg = 0;
  } else if (x >= 1) {
    xProg = 1;
  } else {
    xProg = 0.5-0.5*cos(x*PI);
  }
  return a+(b-a)*xProg;
}
float casesToY(float cases, float day) {
  float preScale = maxes[(int)day];
  float postScale = maxes[min((int)day+1, MAX_LEN-1)];
  float scaleProg = day%1.0;
  float scaleTrue = lerp(preScale, postScale, scaleProg);
  if (expo) {
    float logST = log(scaleTrue);
    float logC = log(cases);
    return Y_MAX+(Y_MIN-Y_MAX)*(logC/logST);
  } else {
    return Y_MAX+(Y_MIN-Y_MAX)*(cases/scaleTrue);
  }
}
float dayToX(float day, float cday) {
  float len = min(cday+1, END_LEN+1);
  return X_MIN+(X_MAX-X_MIN)*((day+1)/len);
}
String keyify(long n) {
  if (n < 1000) {
    return n+"";
  } else if (n < 1000000) {
    if (n%1000 == 0) {
      return (n/1000)+"K";
    } else {
      return nf(n/1000f, 0, 1)+"K";
    }
  } else if (n < 1000000000) {
    if (n%1000000 == 0) {
      return (n/1000000)+"M";
    } else {
      return nf(n/1000000f, 0, 1)+"M";
    }
  } else {
    if (n%1000000000 == 0) {
      return (n/1000000000)+"B";
    } else {
      return nf(n/1000000000f, 0, 1)+"B";
    }
  }
}
String daysToDate(float daysF, boolean longForm) {
  String[] monthNames = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
  int days = (int)daysF+START_DATE+1;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  if (longForm) {
    return monthNames[month-1]+" "+date+", "+year;
    //return year+" "+monthNames[month-1]+" "+date;
  } else {
    return monthNames[month-1]+" "+date;
  }
}
int dateToDays(String s) {
  int year = Integer.parseInt(s.substring(0, 4))-1900;
  int month = Integer.parseInt(s.substring(5, 7))-1;
  int date = Integer.parseInt(s.substring(8, 10));
  Date d1 = new Date(year, month, date, 6, 6, 6);
  int days = (int)(d1.getTime()/86400000L);
  return days;
}
int dateToDaysShort(String s) {
  return dateToDays(s)-START_DATE;
}
String commafy(long f, boolean inFull) {
  if (inFull) {
    String s = f+"";
    String result = "";
    for (int i = 0; i < s.length(); i++) {
      if ((s.length()-i)%3 == 0 && i != 0) {
        result = result+",";
      }
      result = result+s.charAt(i);
    }
    return result;
  } else {
    int n = round(f);
    if (n < 1000) {
      return n+"";
    } else if (n < 10000) {
      return nf(f/1000, 0, 2)+"K";
    } else if (n < 100000) {
      return nf(f/1000, 0, 1)+"K";
    } else if (n < 1000000) {
      return n/1000+"K";
    } else if (n < 10000000) {
      return nf(f/1000000, 0, 2)+"M";
    } else if (n < 100000000) {
      return nf(f/1000000, 0, 1)+"M";
    } else if (n < 1000000000) {
      return n/1000000+"M";
    } else {
      return nf(f/1000000000, 0, 2)+"B";
    }
  }
}
String[] monthNames = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
String dayToDateStr(float daysF, boolean longForm) {
  int days = (int)daysF+START_DATE+1;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  if (longForm) {
    return monthNames[month-1]+" "+date;
  } else {
    return year+"-"+nf(month, 2, 0)+"-"+nf(date, 2, 0);
  }
}
