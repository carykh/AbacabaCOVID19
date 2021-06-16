import com.hamoid.*;
boolean SAVE_VIDEO = true;
String VIDEO_FILENAME = "test.mp4";
VideoExport videoExport;

int TOTAL_DEATHS = 151600;
String[] data = {
"Coronavirus,peak (now)\t108",
"Domestic violence,(women killed)\t137",
"Sudden Infant,Death Syndrome\t144",
"Dogs\t96",
"Snakes\t274",
"Influenza,(USA, now)\t650",
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
"All other,causes\tX"
};
int CAUSE_COUNT = data.length;
Cause[] causes = new Cause[CAUSE_COUNT];
PFont font;
PFont fontBig;

float VA = 250;
float FRAMES_PER_KEYFRAME = 100;
int KEY_FRAME_COUNT = 50;
float[][] coors = new float[KEY_FRAME_COUNT][2];
int THREAT_COUNT = 5500;
int CORONA_COUNT = round(THREAT_COUNT*108F/TOTAL_DEATHS);
Threat[] threats = new Threat[THREAT_COUNT];
float E_R = 50;
PImage bg;
PImage face;
void setup(){
  bg = loadImage("background.png");
  face = loadImage("face.png");
  
  int sum = 0;
  for(int c = 0; c < CAUSE_COUNT; c++){
    String[] s = data[c].split("\t");
    String name = s[0];
    int count = 0;
    if(!s[1].equals("X")){
      count = Integer.parseInt(s[1]);
      sum += count;
    }else{
      count = TOTAL_DEATHS-sum;
    }
    causes[c] = new Cause(c, name, count);
  }
  
  for(int t = 0; t < THREAT_COUNT; t++){
    int type = -1;
    float choice = random(108,TOTAL_DEATHS);
    while(choice >= 0){
      type++;
      choice -= causes[type].count;
    }
    float time = random(FRAMES_PER_KEYFRAME*KEY_FRAME_COUNT);
    if(t >= THREAT_COUNT-CORONA_COUNT){
      type = 0;
      float frac = (THREAT_COUNT-t)*0.2;
      frac += random(-0.05,0.05);
      time = frac*FRAMES_PER_KEYFRAME*KEY_FRAME_COUNT;
    }
    
    float angle = random(0,2*PI);
    float dist = random(E_R*2.02,E_R*9);
    float speed = random(12,17);
    if(random(0,1) < 0.5){
      speed *= -1;
    }
    threats[t] = new Threat(type, time, angle, dist, speed);
  }
  font = loadFont("Gotham-Medium-48.vlw");
  fontBig = loadFont("GothamNarrow-Black-88.vlw");
  size(1920,1080);
  ellipseMode(CENTER);
  for(int kf = 0; kf < KEY_FRAME_COUNT; kf++){
    coors[kf][0] = random(height*0.5-VA,height*0.5+VA);
    coors[kf][1] = random(height*0.5-VA,height*0.5+VA);
  }
  
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILENAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}
int frames = 1;

void draw(){
  background(230,215,190);
  scale(1);
  image(bg,0,0);
  noStroke();
  
  float x = getCoorAt(frames/FRAMES_PER_KEYFRAME,0);
  float y = getCoorAt(frames/FRAMES_PER_KEYFRAME,1);
  float preX = getCoorAt((frames-1)/FRAMES_PER_KEYFRAME,0);
  float preY = getCoorAt((frames-1)/FRAMES_PER_KEYFRAME,1);
  float ang = -atan2(preX-x,preY-y);
  fill(255);
  pushMatrix();
  translate(x,y);
  rotate(ang);
  image(face,-E_R,-E_R,E_R*2,E_R*2);
  popMatrix();
  for(int t = 0; t < THREAT_COUNT; t++){
    float E_RRE = E_R*0.6;
    Threat th = threats[t];
    float youX = getCoorAt(th.approachTime/FRAMES_PER_KEYFRAME,0);
    float youY = getCoorAt(th.approachTime/FRAMES_PER_KEYFRAME,1);
    float approachPointX = youX+cos(th.approachAngle+PI/2)*th.approachDistance;
    float approachPointY = youY+sin(th.approachAngle+PI/2)*th.approachDistance;
    float timeDiff = frames-th.approachTime;
    float dispX = th.approachSpeed*timeDiff*cos(th.approachAngle);
    float dispY = th.approachSpeed*timeDiff*sin(th.approachAngle);
    float finalX = approachPointX+dispX;
    float finalY = approachPointY+dispY;
    if(finalX >= -E_R*2 && finalX < width+E_R*2 &&
      finalY >= -E_R*2 && finalY < height+E_R*2){
      fill(causes[th.type].col);
      noStroke();
      ellipse(finalX,finalY,E_RRE,E_RRE);
      if(th.type == 0){
        noFill();
        stroke(causes[th.type].col);
        strokeWeight(4);
        ellipse(finalX,finalY,E_RRE*1.46,E_RRE*1.46);
        ellipse(finalX,finalY,E_RRE*2.0,E_RRE*2.0);
      }
    }
  }
  /*fill(140,90,40);
  textAlign(LEFT);
  textFont(fontBig,88);
  //text("DEATHS PER DAY",20,height-20);*/
  //saveFrame("corE/corE"+frames+".png");
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
  println(frames+" out of "+(FRAMES_PER_KEYFRAME*KEY_FRAME_COUNT)+" done.");
  frames++;
}
float getCoorAt(float time, int dim){
  float[] vals = new float[4];
  int timeInt = (int)time;
  float timeRem = time%1.0;
  vals[0] = coors[max(0,timeInt-1)][dim];
  vals[1] = coors[timeInt][dim];
  vals[2] = coors[min(KEY_FRAME_COUNT-1,timeInt+1)][dim];
  vals[3] = coors[min(KEY_FRAME_COUNT-1,timeInt+2)][dim];
  return getValue(vals,timeRem);
}
float getValue (float[] p, float x) {
    return p[1] + 0.5 * x*(p[2] - p[0] + x*(2.0*p[0] - 5.0*p[1] + 4.0*p[2] - p[3] + x*(3.0*(p[1] - p[2]) + p[3] - p[0])));
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
