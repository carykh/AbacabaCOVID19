import java.util.*;
import com.hamoid.*;
String VIDEO_FILENAME = "coronavirus_2021-06-24-line_vid.mp4";
boolean SAVE_VIDEO = true;
int LAST_DAY = 541;
int SPECIAL = 1;
int DELAY_BEFORE_ZOOM = 10;
int ZOOM_LENGTH = 26;
float FRAMES_PER_DAY = 40;   // controls the playback speed of the visualization
int ZOOM_SETTLE_ON_DAY = LAST_DAY; // Not really needed anymore. In earlier visualizations, the graph would stop at around Day 100 (since that was the current day), pause, and then gradually (single cosine wave) zoom out to 1.5 years. (so, this variable would be set to ~500.) Now, we're already at 1.5 years, so there's no need.

String[] data;
int DIS_COUNT = 15;
int VIS_SPOT = 12; // Let's show EVERYONE!

Disease[] diseases = new Disease[DIS_COUNT];
int MAX_LEN = 610;
int frames = 0; // This variable also determines what frame the rendering starts on. (So if you want to skip ahead to frame #1,234, set it here!
float currentDay = 0;
int currentDayInt = 0;
float currentDaySim = 0;
float currentDayRem = 0;
float currentDayApp = 0;


float SMOOTH_ZOOMOUT_S = FRAMES_PER_DAY*(LAST_DAY+DELAY_BEFORE_ZOOM);
float SMOOTH_ZOOMOUT_E = FRAMES_PER_DAY*(LAST_DAY+DELAY_BEFORE_ZOOM+ZOOM_LENGTH);

color[] cols =  {color(160,124,255), color(0,242,255),
color(50,255,0), color(245,122,126), color(255,20,80),
color(255,128,0),color(160,124,255),color(160,124,255),
color(50,255,0), color(245,122,126), color(255,255,255),color(255,255,0),
color(245,122,126), color(255,128,0),color(167,255,0)};
long[] maxes = new long[MAX_LEN];
long[] maxesActive = new long[MAX_LEN];
long[] units = {1L,2L,5L,10L,20L,50L,100L,200L,500L,1000L,2000L,5000L,10000L,20000L,50000L,100000L,200000L,500000L,1000000L,2000000L,5000000L,10000000L,20000000L,50000000L,100000000L,200000000L,500000000L,
1000000000L,2000000000L,5000000000L,10000000000L,20000000000L,50000000000L,100000000000L,200000000000L,500000000000L};
int[] vertUnitChoice = new int[MAX_LEN];
int[] horizUnitChoice = new int[MAX_LEN];
int[] textUnitChoice = new int[MAX_LEN];
int[] imgChoice = new int[MAX_LEN];
PImage[] imgArray = new PImage[MAX_LEN];
float X_MIN = 158;
float X_MAX = 1355;
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
float SWN_FAC = 1.94756756;

int START_DATE = dateToDays("2019-12-31");
int END_LEN = 600;

PImage background;
PFont font;
PFont fontBig;
PFont squish;
VideoExport videoExport;

void setup(){
  if(derive){
    X_MAX = 1800;
  }
  if(expoContinue >= 0){
    Y_MIN = 200;
  }
  squish = loadFont("QuickTypeIICondensed-25.vlw");
  font = loadFont("Gotham-Medium-66.vlw");
  fontBig = loadFont("GothamNarrow-Black-120.vlw");
  background = loadImage("background1.png");
  data = loadStrings("worldwideData.tsv");
  for(int day = 0; day < MAX_LEN; day++){
    maxes[day] = 30;
    if(day >= 5){
      maxes[day] = 120;
    }else if(day >= 4){
      maxes[day] = 100;
    }
    
    maxesActive[day] = 0;
    imgChoice[day] = 0;
  }
  for(int d = 0; d < DIS_COUNT; d++){
    diseases[d] = new Disease(d,data[d]);
  }
  for(int day = 0; day < MAX_LEN; day++){
    boolean[] taken = new boolean[DIS_COUNT];
    for(int d = 0; d < DIS_COUNT; d++){
      taken[d] = false;
    }
    int[] list = new int[VIS_SPOT];
    for(int spot = 0; spot < VIS_SPOT; spot++){
      list[spot] = -1;
      float record = 9999;
      int holder = -1;
      for(int d = 0; d < VIS_SPOT; d++){
        float val = casesToY(diseases[d].cases[day],day);
        if(!taken[d] && val <= record && (d != SPECIAL || day < LAST_DAY+7 || expoContinue >= 0)){
          record = val;
          holder = d;
        }
      }
      list[spot] = holder;
      if(holder >= 0){
        taken[holder] = true;
      }
    }
    float cursor = 9999;
    for(int spot = VIS_SPOT-1; spot >= 0; spot--){
      int d = list[spot];
      if(d >= 0){
        float desired = casesToY(diseases[d].cases[day],day);
        if(spot >= 7){
          desired += 85;
        }
        if(spot == 1){
          desired = max(desired,233);
        }
        float gap = WIDGET_H;
        if(diseases[d].cases[day] == maxesActive[day]){
          gap = BWIDGET_H;
          desired += 40;
        }
        float truth = min(desired,cursor-gap);
        cursor = truth;
        diseases[d].labelY[day] = cursor;
        if(diseases[d].labelY[day] < MIN_WIDGET_Y){
          diseases[d].labelY[day] = MIN_WIDGET_Y;
          diseases[list[1]].labelY[day] = MIN_WIDGET_Y+WIDGET_H;
        }
      }
    }
  }
  for(int day = 0; day < MAX_LEN; day++){
    vertUnitChoice[day] = 0;
    while(units[vertUnitChoice[day]] < maxes[day]*0.17){
      vertUnitChoice[day]++;
    }
    horizUnitChoice[day] = 0;
    while(units[horizUnitChoice[day]] < day*0.2){
      horizUnitChoice[day]++;
    }
    if(day >= LAST_DAY+DELAY_BEFORE_ZOOM){
      textUnitChoice[day] = 50;
    }else{
      textUnitChoice[day] = 1;
      while(textUnitChoice[day] < day*0.106){
        textUnitChoice[day]++;
      }
    }
  }
  size(1920,1080);
  ellipseMode(RADIUS);
  frameRate(60);
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}
void draw(){
  background(255);
  noStroke();
  image(background,0,0);
  fill(0,0,0,100);
  rect(0,0,width,height);
  setDayVars();
  drawGridVert(currentDayApp);
  drawGridHoriz(currentDayApp);
  drawLines();
  drawTitles();
  
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  frames++;
}
void setDayVars(){
  if(frames >= SMOOTH_ZOOMOUT_E+60){
    if(SAVE_VIDEO){
      videoExport.endMovie();
    }
    exit();
  }else if(frames >= SMOOTH_ZOOMOUT_S){
    float prog = (frames-SMOOTH_ZOOMOUT_S)/(SMOOTH_ZOOMOUT_E-SMOOTH_ZOOMOUT_S);
    currentDay = cosInter(LAST_DAY+DELAY_BEFORE_ZOOM,ZOOM_SETTLE_ON_DAY,prog);
    currentDayInt = (int)currentDay;
    currentDaySim = currentDay%1.0;
    currentDayRem = currentDaySim;
    currentDayApp = currentDay;
  }else{
    currentDay = min(frames/FRAMES_PER_DAY,END_LEN+0.99);
    currentDayInt = (int)currentDay;
    currentDaySim = currentDay%1.0;
    currentDayRem = snapInter(0,1,currentDaySim);
    currentDayApp = currentDayInt+currentDayRem;
  }
}
void drawTitles(){
  pushMatrix();
  translate(152,0);
  float a = min(max((currentDay-260)/260,0),1);
  scale(1-0.13*a);
  textAlign(LEFT);
  String dateStr = dayToDateStr(currentDayInt,true);
  if(expoContinue >= 0){
    fill(255);
    textFont(font,60);
    text("Projection based on",39,100);
    text(nf((expoContinue-1)*100,0,1)+"% day-on-day growth",39,165);
    textFont(font,30);
    fill(cols[1]);
    text("This is by "+dateStr+" (Day "+currentDayInt+").",39,220);
    fill(255,255,0);
    pushMatrix();
    translate(39,275);
  }else if(derive){
    pushMatrix();
    translate(39,300);
    // translate(777,322);
  }else{
    fill(255);
    textFont(fontBig,120);
    text("DAY "+(currentDayInt),35,185);
    textFont(font,48);
    text("Death counts of epidemics by",39,70);
    text("of outbreak",39,247);
    
    textFont(font,30);
    fill(cols[1]);
    text("For COVID-19,",39,295);
    text("that's "+dateStr+".",39,330);
    fill(255,255,0);
    pushMatrix();
    translate(39,375);
  }
  textFont(font,30);
  text("Video by Cary Huang",0,0);
  text("a.k.a. @realCarykh",0,35);
  textFont(font,24);
  text("youtube.com/1abacaba1",0,67);
  popMatrix();
  popMatrix();
}
void drawGridVert(float cday){
  int c1 = vertUnitChoice[(int)cday];
  int c2 = vertUnitChoice[(int)cday+1];
  if(c1 != c2){
    drawGridVertHelper(c1, cday, lerp(1,0,cday%1.0));
    drawGridVertHelper(c2, cday, lerp(0,1,cday%1.0));
  }else{
    drawGridVertHelper(c1, cday,1.0);
  }
}
void drawGridHoriz(float cday){
  int c1 = horizUnitChoice[(int)cday];
  int c2 = horizUnitChoice[(int)cday+1];
  if(c1 != c2){
    drawGridHorizHelper(c1, cday, lerp(1,0,cday%1.0));
    drawGridHorizHelper(c2, cday, lerp(0,1,cday%1.0));
  }else{
    drawGridHorizHelper(c1, cday,1.0);
  }
}
void drawGridVertHelper(int u, float cday, float alpha){
  long unit = units[u];
  strokeWeight(4);
  stroke(220,220,220,70*alpha);
  fill(220,220,220,110*alpha);
  if(expo){
    for(int ux = 0; ux < units.length; ux++){
      long v = units[ux];
      float lineY = casesToY(v,cday);
      line(X_MIN,lineY,X_MAX,lineY);
      textFont(font,48);
      textAlign(RIGHT);
      text(keyify(v),X_MIN-17,lineY+16);
    }
  }else{
    for(long v = 0; v < maxes[(int)cday+1]*1.5; v += unit){
      float lineY = casesToY(v,cday);
      line(X_MIN,lineY,X_MAX,lineY);
      textFont(font,48);
      textAlign(RIGHT);
      text(keyify(v),X_MIN-17,lineY+16);
    }
  }
}
void drawGridHorizHelper(int u, float cday, float alpha){
  long unit = units[u];
  strokeWeight(4);
  stroke(220,220,220,70*alpha);
  fill(220,220,220,110*alpha);
  for(int v = 0; v < cday; v += unit){
    float lineX = dayToX(v,cday);
    line(lineX,-10,lineX,Y_MAX);
    textFont(font,48);
    textAlign(CENTER);
    text(v,lineX,Y_MAX+58);
  }
  text("DAY",(X_MIN+X_MAX)/2.0,Y_MAX+108);
}
void drawLines(){
  for(int d = 0; d < DIS_COUNT; d++){
    strokeWeight(6);
    Disease di = diseases[d];
    int MAX_I = currentDayInt;
    if(d == SPECIAL && expoContinue < 0){
      MAX_I = min(currentDayInt,LAST_DAY+3);
    }
    if(d == 14 && MAX_I > 365){
      MAX_I = 365;
    }
    for(int day = 0; day <= MAX_I; day++){
      float x1 = dayToX(day,currentDayApp);
      float y1 = casesToY(di.cases[day],currentDayApp);

      float x2 = dayToX(day+1,currentDayApp);
      float y2 = casesToY(di.cases[day+1],currentDayApp);
      
      float xe = x2;
      float ye = y2;
      if(day == currentDayInt){
        xe = lerp(x1,x2,currentDayRem);
        ye = lerp(y1,y2,currentDayRem);
      }
      boolean isFuture = (d == SPECIAL && day >= LAST_DAY);
      if(!(isFuture && expoContinue < 0)){
        if(isFuture){
          if(day%2 == 0){
            strokeWeight(4);
          }else{
            continue;
          }
        }
        
        if(d >= VIS_SPOT){
          strokeWeight(2);
          color c = cols[d];
          float CY = 40;
          float alpha = 140;
          if(d == 14 && currentDay < 90){
            alpha = min(max((currentDay-80)/10,0),1)*160;
          }
          stroke(red(c),green(c),blue(c),alpha);
          drawDottedLine(x1,y1,xe,ye,30,d);
          if(day == MAX_I){
            fill(red(c),green(c),blue(c),alpha);
            textFont(font,30);
            textAlign(RIGHT);
            text(di.name,xe,ye-38);
            text("Estimate",xe,ye-8);
          }
        }else{
          stroke(cols[d]);
          strokeWeight(6);
          line(x1,y1,xe,ye);
          noStroke();
          
          int u1 = textUnitChoice[currentDayInt];
          int u2 = textUnitChoice[currentDayInt+1];
          if(currentDay >= 160 && day > currentDay*0.38){
            u1 *= 2;
            u2 *= 2;
          }
          boolean isMax = (di.cases[day+1] == maxesActive[day+1]);
          
          int base = -1;
          if(d == SPECIAL){
            base = LAST_DAY-1;
          }
          float preAlpha = (((day+u1*100-base)%u1 == 0 || (day >= currentDayInt-1 && day < LAST_DAY+DELAY_BEFORE_ZOOM)) && isMax) ? 1 : 0;
          float postAlpha = ((day+u2*100-base)%u2 == 0 && isMax) ? 1 : 0;
          
          float alpha = lerp(preAlpha,postAlpha,currentDayRem);
          drawEllipse(day+1,di.cases[day+1],xe,ye,d,alpha);
          if(day == 0){
            drawEllipse(day,di.cases[0],x1,y1,d,1);
          }
        }
      }
    }
    if(!(d == SPECIAL && currentDayInt >= LAST_DAY+5 && expoContinue < 0) && !derive && d < VIS_SPOT){
      float yPre = di.labelY[currentDayInt];
      float yPost = di.labelY[currentDayInt+1];
      float ye = lerp(yPre,yPost,currentDayRem);
      pushMatrix();
      translate(X_MAX+20,ye);
      float sc = 1;
      if(d == SPECIAL && currentDayInt == LAST_DAY+4){
        sc = min(max((1-currentDaySim)/0.35f,0),1);
      }
      scale(sc);
      PImage im = di.fixedLogo;
      int zaza = max(1,(int)(currentDay+0.5));
      boolean small = (maxesActive[zaza] != di.cases[zaza]);
      long cases = (long)lerp(di.cases[currentDayInt],di.cases[currentDayInt+1],currentDayRem);
      if(small){
        image(im,0,-18,60,36);
        textFont(font,30);
        fill(cols[d]);
        textAlign(LEFT);
        String deaths = commafy(cases,true);
        int digits = deaths.replace(",","").length();
        String spa = "";
        if(d == SPECIAL){
          spa = " ";
        }
        text(di.vname+": "+spa+deaths,70,10);
        float tw = textWidth(di.vname+": ");
        textFont(squish,25);
        text(di.subname,100+tw+22*digits,10);
      }else{
        image(im,0,-126,180,108);
        fill(cols[d]);
        textFont(font,66);
        textAlign(LEFT);
        text(di.vname,195,-60);
        textFont(font,30);
        text(di.subname,195,-18);
        textFont(font,38);
        text(commafy(cases,true)+" dead",4,23);
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
void drawEllipse(int day, long count, float x, float y, int d, float alpha){
  pushMatrix();
  translate(x,y);
  float age = currentDay-day;
  float fac = min(max((currentDay-25)/50,0),1)*(1-alpha);
  float realR = lerp(ELLIPSE_R,0,fac);
  
  if(age >= 0){
    scale(-cos((age+EPS)*80)*pow(0.5,(age+EPS)*30)+1);
    textFont(font,38);
    noStroke();
    if(realR > 0){
      fill(cols[d]);
      ellipse(0,0,realR,realR);
    }
    pushMatrix();
    /*if(d == SPECIAL && day == LAST_DAY && expoContinue < 0){
      float a = min(max((currentDay-160)/20,0),1);
      translate(a*168,a*116);
    }*/
    if(alpha > 0){
      fill(red(cols[d]),green(cols[d]),blue(cols[d]),alpha*255);
      textAlign(RIGHT);
      if(!derive){
        if(d == SPECIAL && day == LAST_DAY && expoContinue < 0){
          text("COVID-19",0,-ELLIPSE_R-86);
          text(commafy(count,true),0,-ELLIPSE_R-48);
          text("(TBD)",0,-ELLIPSE_R-10);
        }else{
          text(commafy(count,true),0,-ELLIPSE_R-10);
        }
      }
    }
    popMatrix();
  }
  popMatrix();
}
float snapInter(float a, float b, float x){
  if(x < 0.5){
    return lerp(a,b,pow(x,3)/pow(0.5,2));
  }else{
    return lerp(b,a,pow(1-x,3)/pow(0.5,2));
  }
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
float casesToY(float cases, float day){
  float preScale = maxes[(int)day];
  float postScale = maxes[min((int)day+1,MAX_LEN-1)];
  float scaleProg = day%1.0;
  float scaleTrue = lerp(preScale,postScale,scaleProg);
  if(expo){
    float logST = log(scaleTrue);
    float logC = log(cases);
    return Y_MAX+(Y_MIN-Y_MAX)*(logC/logST);
  }else{
    return Y_MAX+(Y_MIN-Y_MAX)*(cases/scaleTrue);
  }
}
float dayToX(float day, float cday){
  float len = min(cday+1,END_LEN+1);
  return X_MIN+(X_MAX-X_MIN)*((day+1)/len);
}
String keyify(long n){
  if(n < 1000){
    return n+"";
  }else if(n < 1000000){
    if(n%1000 == 0){
      return (n/1000)+"K";
    }else{
      return nf(n/1000f,0,1)+"K";
    }
  }else if(n < 1000000000){
    if(n%1000000 == 0){
      return (n/1000000)+"M";
    }else{
      return nf(n/1000000f,0,1)+"M";
    }
  }else{
    if(n%1000000000 == 0){
      return (n/1000000000)+"B";
    }else{
      return nf(n/1000000000f,0,1)+"B";
    }
  }
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
    return monthNames[month-1]+" "+date+", "+year;
    //return year+" "+monthNames[month-1]+" "+date;
  }else{
    return monthNames[month-1]+" "+date;
  }
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
String commafy(long f, boolean inFull) {
  if(inFull){
    String s = f+"";
    String result = "";
    for (int i = 0; i < s.length(); i++) {
      if ((s.length()-i)%3 == 0 && i != 0) {
        result = result+",";
      }
      result = result+s.charAt(i);
    }
    return result;
  }else{
    int n = round(f);
    if(n < 1000){
      return n+"";
    }else if(n < 10000){
      return nf(f/1000,0,2)+"K";
    }else if(n < 100000){
      return nf(f/1000,0,1)+"K";
    }else if(n < 1000000){
      return n/1000+"K";
    }else if(n < 10000000){
      return nf(f/1000000,0,2)+"M";
    }else if(n < 100000000){
      return nf(f/1000000,0,1)+"M";
    }else if(n < 1000000000){
      return n/1000000+"M";
    }else{
      return nf(f/1000000000,0,2)+"B";
    }
  }
}
String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
String dayToDateStr(float daysF, boolean longForm){
  int days = (int)daysF+START_DATE+1;
  Date d1 = new Date();
  d1.setTime(days*86400000l);
  int year = d1.getYear()+1900;
  int month = d1.getMonth()+1;
  int date = d1.getDate();
  if(longForm){
    return monthNames[month-1]+" "+date+", "+year;
  }else{
    return year+"-"+nf(month,2,0)+"-"+nf(date,2,0);
  }
}
