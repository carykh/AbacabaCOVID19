class Dot{
  Point[] coor;
  int[] caseType;
  // -1 = nonexistent
  // 0 = active, not serious (golden)
  // 1 = active, serious (red)
  // 2 = recovered (green)
  // 3 = dead (dark gray)
  
  // 4 = mini active, not serious (golden)
  // 5 = mini active, serious (red)
  // 6 = mini recovered (green)
  // 7 = mini dead (dark gray)
  
  public Dot(int startDay, PImage map, Point prePoint){
    coor = new Point[DAY_LEN];
    caseType = new int[DAY_LEN];
    for(int day = 0; day < DAY_LEN; day++){
      caseType[day] = -1;
      if(day >= startDay){
        caseType[day] = 0;
      }
      if(day == startDay){
        if(prePoint == null){
          coor[day] = findSpot(map,-100,-100, (startDay == 0));
        }else{
          coor[day] = prePoint;
        }
        if(day >= 1){
          coor[day-1] = coor[day];
        }
      }else if(day >= startDay){
        int pX = coor[day-1].x;
        int pY = coor[day-1].y;
        coor[day] = findSpot(map,pX,pY, false);
      }else{
        coor[day] = new Point(-100,-100);
      }
    }
  }
  public Dot(int dayS, int dayE, int c, PImage map){ // mini dot
    coor = new Point[DAY_LEN];
    caseType = new int[DAY_LEN];
    for(int day = 0; day < DAY_LEN; day++){
      caseType[day] = -1;
      if(day >= dayS && day < dayE){
        caseType[day] = c;
      }
      if(day == dayS){
        coor[day] = findSpot(map,-100,-100, true);
        if(day >= 1){
          coor[day-1] = coor[day];
        }
      }else if(day >= dayS && day < dayE && c != 7){
        int pX = coor[day-1].x;
        int pY = coor[day-1].y;
        coor[day] = findSpot(map,pX,pY, false);
      }else if(day >= 1 && (day >= dayE || c == 7)){
        coor[day] = coor[day-1];
      }else{
        coor[day] = new Point(-100,-100);
      }
    }
  }
  Point findSpot(PImage map, int prevX, int prevY, boolean avoidEdges){
    if(alpha(map.get(0,0)) > 128 && green(map.get(0,0)) > red(map.get(0,0))-128){
      return new Point(-100,-100);
    }
    int choiceX = -1;
    int choiceY = -1;
    if(prevX < 0){
      while(choiceX < 0 || !(alpha(map.get(choiceX,choiceY)) >= 128 && (!avoidEdges || red(map.get(choiceX,choiceY)) >= 128))){
        choiceX = (int)random(0,width);
        choiceY = (int)random(0,height);
      }
      int ANGLES = 8;
      float DIST = 20;
      boolean fail = false;
      for(int a = 0; a < ANGLES; a++){
        int addX = (int)(DIST*cos(2.0*PI/((float)ANGLES)*a));
        int addY = (int)(DIST*sin(2.0*PI/((float)ANGLES)*a));
        int newX = choiceX+addX;
        int newY = choiceY+addY;
        if(newX < 0 || newX >= width || newY < 0 || newY >= height){
          fail = true;
          break;
        }
        if(alpha(map.get(newX,newY)) <= 128){
          fail = true;
          break;
        }
      }
    }else{
      while(choiceX < 0 || alpha(map.get(choiceX,choiceY)) <= 128){
        choiceX = prevX+(int)random(-12,12);
        choiceY = prevY+(int)random(-12,12);
      }
    }
    return new Point(choiceX,choiceY);
  }
}