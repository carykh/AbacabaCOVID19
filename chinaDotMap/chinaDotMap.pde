import java.util.*; 
import com.hamoid.*;
boolean SAVE_VIDEO = true;
String VIDEO_FILENAME = "test.mp4";
VideoExport videoExport;

int START_DATE = dateToDays("2019-12-31");

int REGION_COUNT = 83;
int DAY_LEN = 57;
int CASE_TYPES = 4;
int[][] totals = new int[DAY_LEN][CASE_TYPES];
Region[] regions = new Region[REGION_COUNT];
PImage bg;
String[] data;
String[] totalData;
color[] cols = {color(155,105,0,140),color(255,0,0,140),color(0,130,130,140),color(114,0,0,255)};
PFont titleFont;
PFont mainFont;
void setup(){
  titleFont = loadFont("GothamNarrow-Black-120.vlw");
  mainFont = loadFont("Gotham-Medium-40.vlw");
  bg = loadImage("cvwm/cvwm0001.png");
  data = loadStrings("dataExtended.txt");
  totalData = loadStrings("data2.txt");
  String[] line1 = tabify(totalData[0]).split("\t");
  String[] line2 = tabify(totalData[1]).split("\t");
  for(int day = 0; day < DAY_LEN; day++){
    totals[day][0] = Integer.parseInt(line1[day+2]);
    totals[day][3] = Integer.parseInt(line2[day+2]);
    totals[day][1] = 0; 
  }
  String[] parts = data[0].split("\t");
  for(int r = 0; r < REGION_COUNT; r++){
    PImage img = loadImage("cvwm/cvwm"+nf(r+2,4,0)+".png");
    regions[r] = new Region(parts[r+1],img);
    println("Loaded map for the region of "+regions[r].name);
  }
  for(int day = 0; day < DAY_LEN; day++){
    parts = data[day+1].split("\t");
    for(int r = 0; r < min(parts.length-1,REGION_COUNT); r++){
      Region re = regions[r];
      String datum = parts[r+1];
      String[] miniParts = datum.split("-");
      int caseTypesToCount = miniParts.length;
      if(miniParts.length == 2){
        caseTypesToCount = 1;
      }
      if(datum.length() == 0){
        caseTypesToCount = 0;
      }
      for(int caseType = 0; caseType < caseTypesToCount; caseType++){
        if(/*re.name.equals("shanghai") && day < 28 && */caseType == 1){
        }else{
          int val = Integer.parseInt(miniParts[caseType]);
          re.counts[day][caseType] = val;
          if(caseType == 2){
            totals[day][1] += val;
          }
          if(caseType == 0 && val >= 1 && (day == 0 || re.counts[day-1][caseType] == 0)){
            re.DAY_OF_INFECTION = day;
          }
        }
      }
    }
  }
  for(int r = 0; r < REGION_COUNT; r++){
    Region re = regions[r];
    println("Starting the region of "+re.name);
    for(int day = 0; day < DAY_LEN; day++){
      for(int c = 0; c < 4; c++){
        if(day >= 1){
          re.counts[day][c] = max(re.counts[day-1][c],re.counts[day][c]);
        }
        int prev = 0;
        if(day >= 1){
          prev = re.counts[day-1][c];
        }
        int curr = re.counts[day][c];
        
        int prevDotCount = prev/20;
        int currDotCount = curr/20;
        int numNew = currDotCount-prevDotCount;
        if(curr >= 1 && curr < 20 && prev == 0){
          int endDay = day;
          while(endDay < DAY_LEN && re.counts[endDay][c] < 20){
            endDay++;
          }
          if(c == 3){
            println("yoyle, death dots for "+re.name+": "+day+" - "+endDay);
          }
          re.addMiniDot(day,endDay,c+CASE_TYPES);
        }
        for(int cou = 0; cou < numNew; cou++){
          if(c == 0){
            re.addDot(day,(prevDotCount == 0));
          }else{
            re.changeDot(day,0,c);
            if(c == 1){
              println("Changed a dot to serious in "+re.name);
            }
          }
        }
        for(int cou = 0; cou < -numNew; cou++){
          if(c == 0){
            println("You should never get here.");
            assert(false);
          }else{
            re.changeDot(day,c,0);
          }
        }
      }
    }
  }
  for(int day = 0; day < DAY_LEN; day++){
    totals[day][2] = totals[day][0]-totals[day][1]-totals[day][3];
    //println(totals[day][1]+"\t"+totals[day][2]+"\t"+totals[day][3]);
  }
  size(1920,1080);
  frameRate(30);
  smooth();
  ellipseMode(RADIUS);
  println("Done with first parsing.");
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}

int frames = 0;
float FRAMES_PER_DAY = 85.696875;
int currentDayInt = 0;
int currentDayIntApp = 0;
float currentDayRem = 0;
float currentDayTrans = 0;
void draw(){
  setDayVars();
  drawMaps();
  drawDots();
  drawTitle();
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  frames++;
}
void drawMaps(){
  image(bg,0,0);
  float alpha = min(max((1-abs(currentDayTrans-0.5)*2.2),0),1);
  for(int r = 0; r < REGION_COUNT; r++){
    Region re = regions[r];
    if(re.DAY_OF_INFECTION == currentDayInt+1){
      tint(0,0,0,alpha*80);
      image(re.map,0,0);
      noTint();
    }
  }
}
void drawDots(){
  for(int r = 0; r < REGION_COUNT; r++){
    Region re = regions[r];
    for(int d = 0; d < re.dots.size(); d++){
      Dot dot = re.dots.get(d);
      drawDot(dot,currentDayInt,currentDayTrans);
    }
  }
}
void drawTitle(){
  String str = daysToDate(currentDayIntApp,true);
  
  textFont(titleFont,120);
  textAlign(LEFT);
  fill(208);
  noStroke();
  rect(0,0,780,135);
  rect(730,0,380,200);
  rect(730,0,440,170);
  
  fill(0);
  text(str,20,110);
  
  int[] d = totals[currentDayIntApp];
  int[] dBase = totals[currentDayInt];
  int[] dNBase = totals[min(currentDayInt+1,DAY_LEN-1)];
  float[] percs = new float[3];
  float[] percsA = new float[3];
  for(int i = 0; i < 3; i++){
    percs[i] = 100*((float)d[i+1])/d[0];
    float thisStat = ((float)dBase[i+1])/dBase[0];
    float nextStat = ((float)dNBase[i+1])/dNBase[0];
    percsA[i] = lerp(thisStat,nextStat,currentDayTrans);
  }
  
  float tX = 820;
  float tW = 250;
  fill(0);
  textFont(mainFont,36);
  textAlign(LEFT);
  text("All cases: "+commafy(d[0]),tX,50);
  
  int[] a = {2,0,3};
  String[] strs = {"Recoveries: ","Active cases: ","Deaths: "};
  for(int stat = 0; stat < 3; stat++){
    fill(fullOpacity(cols[a[stat]]));
    text(strs[stat]+commafy(d[stat+1]),tX,110+stat*80);
    text(nf(percs[stat],0,1)+"%",tX+max(25,tW*percsA[stat]+10),150+stat*80);
    rect(tX,117+stat*80,tW*percsA[stat],39);
  }
}
color fullOpacity(color c){
  return color(red(c),green(c),blue(c),255);
}
void setDayVars(){
  float days = ((float)frames)/FRAMES_PER_DAY;
  currentDayInt = (int)days;
  currentDayRem = days%1.0;
  currentDayTrans = snapInter(0,1,currentDayRem);
  currentDayIntApp = (int)(days+0.5);
}
float snapInter(float a, float b, float x) {
  if (x < 0.5) {
    return lerp(a, b, pow(x, 3)/pow(0.5, 2));
  } else {
    return lerp(b, a, pow(1-x, 3)/pow(0.5, 2));
  }
}
void drawDot(Dot dot, int d0, float prog){
  int d1 = min(d0+1,DAY_LEN-1);
  int caseType0 = dot.caseType[d0];
  int caseType1 = dot.caseType[d1];
  
  if(caseType0 >= 4){
    noStroke();
    fill(cols[caseType0-CASE_TYPES]);
    float pX = lerp(dot.coor[d0].x,dot.coor[d1].x,prog);
    float pY = lerp(dot.coor[d0].y,dot.coor[d1].y,prog);
    float pR = lerp(dot.coor[d0].r,dot.coor[d1].r,prog);
    float s = 1;
    if(caseType1 == -1){
      s = 1-prog;
    }
    pushMatrix();
    translate(pX,pY);
    scale(s);
    ellipse(0,0,3.5,3.5);
    popMatrix();
  }else if(caseType0 >= 0){
    noStroke();
    fill(colorLerp(cols[caseType0],cols[caseType1],prog));
    float pX = lerp(dot.coor[d0].x,dot.coor[d1].x,prog);
    float pY = lerp(dot.coor[d0].y,dot.coor[d1].y,prog);
    float pR = lerp(dot.coor[d0].r,dot.coor[d1].r,prog);
    pushMatrix();
    translate(pX,pY);
    rotate(pR);
    drawStar(0,0,8,3.7,5);
    popMatrix();
  }else if(caseType1 >= 4){
    noStroke();
    fill(cols[caseType1-CASE_TYPES]);
    pushMatrix();
    translate(dot.coor[d0].x,dot.coor[d0].y);
    scale(prog);
    ellipse(0,0,3.5,3.5);
    popMatrix();
  }else if(caseType1 >= 0){
    noStroke();
    fill(cols[caseType1]);
    pushMatrix();
    translate(dot.coor[d0].x,dot.coor[d0].y);
    rotate(dot.coor[d1].r);
    scale(prog);
    drawStar(0,0,8,3.7,5);
    popMatrix();
  }
}
color colorLerp(color a, color b, float x){
  float newRed = lerp(red(a),red(b),x);
  float newGreen = lerp(green(a),green(b),x);
  float newBlue = lerp(blue(a),blue(b),x);
  float newAlpha = lerp(alpha(a),alpha(b),x);
  return color(newRed,newGreen,newBlue,newAlpha);
}
void drawStar(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a+halfAngle) * radius1;
    sy = y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}
String keyify(int n) {
  if (n < 1000) {
    return n+"";
  } else if (n < 1000000) {
    if (n%1000 == 0) {
      return (n/1000)+"K";
    } else {
      return nf(n/1000f, 0, 1)+"K";
    }
  }
  if (n%1000000 == 0) {
    return (n/1000000)+"M";
  } else {
    return nf(n/1000000f, 0, 1)+"M";
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
String tabify(String s){
  String input = s;
  int div = input.indexOf(")");
  String pre = input.substring(0,div);
  String post = input.substring(div,input.length());
  while(post.indexOf("  ") >= 0){
    post = post.replace("  "," ");
  }
  post = post.replace(" ","\t");
  String modded = pre+post;
  return modded;
}
