class Country{
  String name;
  int[] deaths;
  int[][] startEnd;
  PImage flag;
  public Country(String n){
    name = n;
    deaths = new int[WEEK_COUNT];
    startEnd = new int[WEEK_COUNT][2];
    for(int w = 0; w < WEEK_COUNT; w++){
      deaths[w] = 0;
      startEnd[w][0] = 0;
      startEnd[w][1] = 0;
    }
    String filename = "../../_flags/flag-of-"+flagFileize(name)+".png";
    File f = dataFile(filename); 
    if(f.isFile()){
      flag = loadImage(filename);
    }else{
      flag = null;
    }
  }
  int getNewDeaths(int day){
    if(name.equals("china") && day <= 2){
      if(day == 1){
        return 1;
      }else if(day == 2){
        return 17;
      }
    }
    if(day == 0){
      return deaths[0];
    }else{
      return deaths[day]-deaths[day-1];
    }
  }
}
