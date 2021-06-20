class Disease{
  String name;
  String vname;
  String subname;
  long[] cases;
  float[] labelY;
  String startDate = "";
  PImage logo;
  PGraphics fixedLogo;
  
  int FL_W = 180;
  int FL_H = 108;
  public Disease(int i, String input){
    String[] parts = input.split("\t");
    name = parts[0];
    vname = parts[0];
    subname = parts[2];
    
    startDate = parts[4];
    cases = new long[MAX_LEN];
    
    if(derive){
      int[] preCases = new int[MAX_LEN];
      for(int day = 1; day < MAX_LEN; day++){
        preCases[day] = Integer.parseInt(parts[min(day+5,parts.length-1)]);
      }
      for(int day = 1; day < MAX_LEN; day++){
        int WIDTH = 0;
        if(i == 3){
          WIDTH = 14;
        }else if(i != 1){
          WIDTH = 3;
        }
        float summer = 0;
        float counter = 0;
        int min = max(1,day-WIDTH);
        int max = min(MAX_LEN-1,day+WIDTH);
        for(int dz = min; dz <= max; dz++){
          int val = preCases[dz]-preCases[dz-1];
          float dist = abs(dz-day);
          float weight = 1;
          if(WIDTH >= 1){
            weight = cos(PI*dist/WIDTH)+1;
          }
          counter += weight;
          summer += weight*val;
        }
        cases[day] = round(summer/counter);
      }
    }else{
      for(int day = 1; day < MAX_LEN; day++){
        cases[day] = Integer.parseInt(parts[min(day+5,parts.length-1)]);
        if(i == SPECIAL && expoContinue >= 0 && day >= LAST_DAY+1){
          int added = (int)((cases[day-1]-cases[day-2])*expoContinue);
          cases[day] = cases[day-1]+added;
        }
        long val = cases[day];
        
        if(i < VIS_SPOT || day >= 160){
          if(val > maxes[day]){
            maxes[day] = val;
          }
        }
        if(i < VIS_SPOT){
          if(day <= parts.length){
            if(cases[day] > maxesActive[day]){
              maxesActive[day] = cases[day];
            }
          }
        }
      }
    }
    logo = loadImage("img"+i+".jpg");
    fixedLogo = createGraphics(FL_W,FL_H);
    fixedLogo.beginDraw();
    float aspectRatio = ((float)logo.width)/logo.height;
    if(aspectRatio > 1.6){
      float imgH = FL_H;
      float imgW = imgH/logo.height*logo.width;
      float surplus = imgW-FL_W;
      fixedLogo.image(logo,-surplus/2.0,0,imgW,imgH);
    }else{
      float imgW = FL_W;
      float imgH = imgW/logo.width*logo.height;
      float surplus = imgH-FL_H;
      fixedLogo.image(logo,0,-surplus/2.0,imgW,imgH);
    }
    fixedLogo.endDraw();
    labelY = new float[MAX_LEN];
  }
}
