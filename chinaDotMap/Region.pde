class Region{
  String name;
  PImage map;
  int[][] counts;
  ArrayList<Dot> dots;
  Point miniDotSpot;
  int DAY_OF_INFECTION = -1;
  public Region(String n, PImage img){
    name = n;
    map = img;
    counts = new int[DAY_LEN][CASE_TYPES];
    for(int day = 0; day < DAY_LEN; day++){
      for(int c = 0; c < CASE_TYPES; c++){
        counts[day][c] = 0;
      }
    }
    dots = new ArrayList<Dot>(0);
    miniDotSpot = null;
  }
  void addDot(int day, boolean UMDS){
    Point mds = null;
    if(UMDS){
      mds = miniDotSpot;
    }
    dots.add(new Dot(day,map,mds));
  }
  void addMiniDot(int dayS, int dayE, int caseType){
    Dot miniDot = new Dot(dayS,dayE,caseType,map);
    dots.add(miniDot);
    if(caseType == 4){
      miniDotSpot = miniDot.coor[dayE-1];
    }
  }
  void changeDot(int day, int s, int e){
    int choiceI = -1;
    while(choiceI == -1 || dots.get(choiceI).caseType[day] != s){
      choiceI = (int)random(0,dots.size());
    }
    for(int d2 = day; d2 < DAY_LEN; d2++){
      Dot dot = dots.get(choiceI);
      dot.caseType[d2] = e;
      if(e == 3 && day >= 1){
        dot.coor[d2] = dot.coor[d2-1]; // Dead people can't move
      }
    }
  }
}