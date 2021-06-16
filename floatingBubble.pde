import com.hamoid.*;

int TOTAL_DEATHS = 151600;
String[] data = {
  "COVID-19,(Feb 10, 2020)\t108", 
  "Domestic violence\t137", 
  "Sudden Infant,Death Syndrome\t144", 
  "Killed by dogs\t96", 
  "Killed by snakes\t274", 
  "Influenza,(seasonal)\t1288", 
  "Drowning\t877", 
  "Homicide\t1095", 
  "Malaria\t1599", 
  "Alzheimer’s,Disease\t1916", 
  "Accidental suffocation and,strangulation in bed (USA)\t2", 
  "Suicide\t3000", 
  "Car crashes\t3287", 
  "Stroke\t13689", 
  "Ischemic,Heart Disease\t24641", 
  "Cancer\t26283", 
  "COVID-19,(Jan 20, 2021)\t17350"
};
int CAUSE_COUNT = data.length;
Cause[] causes = new Cause[CAUSE_COUNT];
PFont font;
PFont fontBig;
boolean saveVideo = false;
VideoExport videoExport;

void setup() {
  int sum = 0;
  for (int c = 0; c < CAUSE_COUNT; c++) {
    String[] s = data[c].split("\t");
    String name = s[0];
    int count = 0;
    if (!s[1].equals("X")) {
      count = Integer.parseInt(s[1]);
      sum += count;
    } else {
      count = TOTAL_DEATHS-sum;
    }
    causes[c] = new Cause(c, name, count);
  }
  font = loadFont("Gotham-Medium-48.vlw");
  fontBig = loadFont("GothamNarrow-Black-88.vlw");
  size(1920, 1080);
  ellipseMode(CENTER);
  
  if(saveVideo){
    videoExport = new VideoExport(this, "covid19_bubble_graph_2021-01-20.mp4");
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}
int causeOn = 0;
float withinCause = 0;
float FRAMES_PER_CAUSE = 60;//2*62.068965517;
int frames = 0;//(int)(FRAMES_PER_CAUSE*15);
void draw() {
  causeOn = (int)(frames/FRAMES_PER_CAUSE);
  withinCause = frames%FRAMES_PER_CAUSE;
  float wc = ((float)withinCause)/FRAMES_PER_CAUSE;

  background(230, 215, 190);

  if (causeOn >= 16) {
    float es = causeOn+withinCause/FRAMES_PER_CAUSE;
    float s = 0.5-0.5*cos(min(max((es-16)/1.0, 0), 1)*PI);
    scale(1.00-0.19*s);
    translate(500*s, 120*s);
  }

  fill(140, 90, 40);
  textAlign(LEFT);
  textFont(fontBig, 88);
  text("DEATHS PER DAY", 20, height-20);

  for (int c = 0; c <= min(CAUSE_COUNT-1, causeOn); c++) {
    float appC = c;
    if (c == CAUSE_COUNT-1) {
      appC = c+2;
    }
    Cause ca = causes[c];
    float x = 0;
    float y = 0;
    if (c < 7) {
      x = (c-0+0.5)*(width/7.0);
      y = height*0.137;//+(c%3-1)*48;
    } else if (c < 13) {
      x = (c-7+0.5)*(width/6.0);
      y = height*0.31;//+(c%3-1)*48;
    } else if (c < 16) {
      x = (c-13+0.5)*(width/3.0);
      y = height*0.68;//+(c%3-1)*48;
    } else {
      x = -222;
      y = 300;//+(c%3-1)*48;
    }
    noStroke();
    fill(ca.col);
    int ellipseCount = ceil(ca.count/100F);
    float partial = (ca.count/100F)%1.0;
    for (int e = 0; e < ellipseCount; e++) {
      float e2 = sqrt(e+1);
      float ang = e2*3.8;
      float x2 = cos(ang)*e2*19;
      float y2 = sin(ang)*e2*19;
      pushMatrix();
      translate(width/2, height/2);
      float eProg = ((float)e)/ellipseCount;
      float age = (causeOn-appC)+wc-0.5*eProg;
      float s = (age >= 0) ? 1.0+0.01*cos(age*2) : 0;
      s *= 1.0-1.0*pow(0.5, age*20);
      scale(s);
      translate(-width/2+x+x2, -height/2+y+y2);
      if (e == ellipseCount-1) {
        PGraphics semi = createGraphics(50, 100);
        semi.beginDraw();
        semi.noStroke();
        semi.fill(ca.col);
        semi.ellipse(0, 50, 100, 100);
        semi.endDraw();
        if (partial >= 0.5) {
          pushMatrix();
          rotate(PI+ang+PI*(partial-0.5));
          image(semi, 0, -15, 15, 30);
          popMatrix();
          pushMatrix();
          rotate(PI+ang-PI*(partial-0.5));
          image(semi, 0, -15, 15, 30);
          popMatrix();
        } else {
          PGraphics semi2 = createGraphics(50, 100);
          semi2.beginDraw();
          semi2.translate(0, 50);
          semi2.rotate(PI-PI*partial*2);
          semi2.image(semi, 0, -50);

          semi2.endDraw();
          pushMatrix();
          rotate(ang+PI/2+partial*PI);
          image(semi2, 0, -15, 15, 30);
          popMatrix();
        }
      } else {
        ellipse(0, 0, 30, 30);
      }
      popMatrix();
    }


    float textY = y;
    if (c == 6) {
      textY -= 100;
    } else if (c == 5) {
      textY -= 90;
    } else if (c < 6) {
      textY -= 80;
    }
    float age = (causeOn-appC)+wc;
    float s = (age >= 0) ? 1.0+0.01*cos(age*2) : 0;
    s *= 1.0-1.0*pow(0.5, age*20);
    pushMatrix();
    translate(width/2, height/2);
    scale(s);
    translate(-width/2+x, -height/2+textY);
    textFont(font, 28);
    textAlign(CENTER);

    boolean label = (c == 5 || (c >= 7 && c != 10));
    String n = ca.name;
    if (n.indexOf(",") >= 0) {
      String nPre = n.substring(0, n.indexOf(","));
      String nPost = n.substring(n.indexOf(",")+1, n.length());
      if (label) {
        float labelW = max(textWidth(nPre), textWidth(nPost))+6;
        fill(230, 215, 190, 200);
        rect(-labelW/2, -40, labelW, 88);
      }
      fill(140, 90, 40);
      text(nPre, 0, -14);
      text(nPost, 0, 14);
      text(commafy(ca.count), 0, 42);
    } else {
      if (label) {
        float labelW = textWidth(n)+10;
        fill(230, 215, 190, 200);
        rect(-labelW/2, -26, labelW, 60);
      }
      fill(140, 90, 40);
      text(n, 0, 0);
      text(commafy(ca.count), 0, 28);
    }
    popMatrix();
  }
  if(saveVideo){
    videoExport.saveFrame();
  }
  println(causeOn+" / "+(CAUSE_COUNT+4));
  frames++;
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
