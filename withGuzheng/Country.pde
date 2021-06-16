class Country{
  String name;
  int pop = 0;
  int[][] data = new int[CASE_TYPES*2][DAY_LEN];
  int[] perCapita = new int[DAY_LEN];
  int[] ranks = new int[DAY_LEN];
  int[] maxes = new int[DAY_LEN];
  int[] cpt = new int[DAY_LEN];
  PImage flag;
  String code = "???";
  
  int WIDGET_W = 900;
  int WIDGET_H = 216;
  int M = 6;
  int LABEL_W = 155;
  int LH = 52;
  int WIDGET_VW = (int)(WIDGET_W-LABEL_W-M*3.5);
  int WIDGET_VH = WIDGET_H-M*2;
  float GRAPH_Y_RATIO = 0.9;
  
  public Country(boolean world){
    name = "";
    for(int day = 0; day < DAY_LEN; day++){
      for(int ct = 0; ct < CASE_TYPES*2; ct++){
        data[ct][day] = 0;
      }
      ranks[day] = 0;
      perCapita[day] = 0;
      cpt[day] = 0;
    }
    pop = 0;
    /*if(world){
      LABEL_W = 188;
    }*/
  }
  void setName(String s){
    name = s;
    String s2 = capitalize(s).replace(" ","-");
    flag = loadImage("flags/flag-of-"+s2+".png");
  }
  void setPC(int day){
    if(data[1][day] == 0){
      perCapita[day] = 2000000000;
    }else{
      perCapita[day] = (int)round(((float)pop)/data[1][day]);
    }
    if(data[3][day] >= maxes[day]){
      for(int d = day; d < DAY_LEN; d++){
        maxes[d] = data[3][day];
      }
    }
  }
  PGraphics getGraph(){
    PGraphics g = createGraphics(WIDGET_VW,WIDGET_VH);
    g.beginDraw();
    g.background(0);
    for(int weeksAgo = 1; weeksAgo <= 7; weeksAgo+=2){
      g.noStroke();
      float x1 = weeksAgoToX(weeksAgo);
      float x2 = weeksAgoToX(weeksAgo+1);
      g.fill(255,255,255,27);
      g.rect(x1,0,x2-x1,WIDGET_VH);
    }
    for(int ct = 3; ct < 6; ct++){
      for(int day = 0; day <= currentDayInt; day++){
        int thisVal = data[ct][min(DAY_LEN-1,day)];
        int nextVal = data[ct][min(DAY_LEN-1,day+1)];
        float x1 = dayToX(day);
        float y1 = valToY(thisVal);
        float x2 = dayToX(day+1);
        float y2 = valToY(nextVal);
        g.noStroke();
        g.fill(cols[ct-3]);
        g.beginShape();
        g.vertex(x1,y1);
        g.vertex(x2,y2);
        g.vertex(x2,WIDGET_VH);
        g.vertex(x1,WIDGET_VH);
        g.endShape(CLOSE);
      }
    }
    g.endDraw();
    return g;
  }
  float dayToX(float day){
    float BOOST = 1.5;
    return (int)(BOOST*(day-currentDaySim)/DAY_LEN*WIDGET_VW+WIDGET_VW);
  }
  float weeksAgoToX(float weeks){
    float BOOST = 1.25;
    return WIDGET_VW-(int)(BOOST*(weeks*7)/DAY_LEN*WIDGET_VW);
  }
  float valToY(float val){
    int[] cappedMaxes = new int[DAY_LEN];
    for(int day = 0; day < DAY_LEN; day++){
      cappedMaxes[day] = max(10,data[3][day]);
    }
    double maxVal = snapIndex(cappedMaxes,currentDay);
    return (float)(WIDGET_VH-WIDGET_VH*GRAPH_Y_RATIO*val/maxVal);
  }
  void drawBigWidget(boolean world){
    if(!world){
      PGraphics graph = getGraph();
      image(graph,M*1.5,M);
      
      textFont(titleFont,54);
      textAlign(LEFT);
      fill(255);
      String str = capitalize(name);
      float imgH = 50.0;
      float imgW = 50.0/flag.height*flag.width;
      image(flag,17,17,imgW,imgH);
      text(str,imgW+28,61);
      fill(cols[1]);
      pushMatrix();
      translate(20,78);
      textFont(contentFont,36);
      String str2 = "None";
      if(perCapita[CDIA] < 2000000000){
        str2 = "1 in "+abbrNumber(perCapita[CDIA]); 
      }
      rect(0,0,textWidth(str2)+20,46,10);
      fill(0);
      text(str2,10,36);
      popMatrix();
    }
    for(int ct = 0; ct < 3; ct++){
      fill(cols[ct]);
      pushMatrix();
      if(world){
        translate(-LABEL_W-M*2,M+LH*ct);
        rect(0,0,LABEL_W,LH-M,10);
        image(drawRollingText(ct, data[ct], LABEL_W-8, LH-M, 1.0, 0, 0),8,0);
      }else{
        translate(WIDGET_VW+3*M,M+LH*ct);
        rect(0,0,LABEL_W,LH-M,10);
        image(drawRollingText(ct, data[ct], LABEL_W-8, LH-M, 1.0, 0, 0),8,0);
      }
      
      popMatrix();
    }
    if(world){
      pushMatrix();
      translate(-LABEL_W-M*2,M-LH);
      fill(cols[3]);
      rect(0,0,LABEL_W,LH-M,10);
      image(drawRollingText(3, countryCounts, LABEL_W-8, LH-M, 1.0, 0, 0),8,0);
      popMatrix();
    }else{
      pushMatrix();
      translate(WIDGET_VW+3*M,M+LH*3-3);
      image(drawRollingText(3, cpt, LABEL_W-8, LH-M, 1.0, 2, 0),0,0);
      popMatrix();
    }
  }
  void drawSmallWidget(boolean tiny){
    float SLABEL_W = 57;
    float SLABEL_DX = 61;
    float SW_H = 26.0;
    float SLABEL_S = (SW_H+2)/(LH-M);
    fill(255);
    textFont(contentFontSmall,27);
    textAlign(CENTER);
    float imgH = SW_H+3;
    float imgW = imgH/flag.height*flag.width;
    
    image(flag,0,-1,imgW,imgH);
    if(tiny){
      pushMatrix();
      translate(imgW,0);
      image(drawRollingText(2, data[1], (int)SLABEL_W-5, (int)SW_H+2, SLABEL_S, 1, 0),5,0);
      popMatrix();
    }else{
      float CODE_WIDTH = 125;
      text(code,(imgW+CODE_WIDTH)/2.0,24);
      for(int ct = 0; ct < 3; ct++){
        fill(cols[ct]);
        pushMatrix();
        translate(CODE_WIDTH+SLABEL_DX*ct,0);
        rect(0,-1,SLABEL_W,SW_H+2,5);
        image(drawRollingText(ct, data[ct], (int)SLABEL_W-5, (int)SW_H+2, SLABEL_S, 1, 0),5,0);
        popMatrix();
      }
    }
  }
  void setCums(int day){
    data[5][day] = data[2][day];
    data[4][day] = data[1][day]+data[2][day];
    data[3][day] = data[0][day]+data[1][day]+data[2][day];
  }
  float getRankingValue(int day){
    float tiebreaker = ((float)(data[2][day]+1))/4000.0;
    tiebreaker = min(max(tiebreaker,0),0.99);
    float tiebreaker2 = 1-log(pop)/log(2000000000);
    tiebreaker2 = min(max(tiebreaker2,0),0.99);
    return data[1][day]+tiebreaker+tiebreaker2*0.0001;//random(0,1);//tiebreaker;
    //return 2000000000-perCapita[day];
  }
  void average(int day){
    for(int ct = 0; ct < 3; ct++){
      data[ct][day] = (data[ct][day-1]+data[ct][day+1])/2;
    }
    setCums(day);
  }
}