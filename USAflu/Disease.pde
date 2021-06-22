class Disease{
  String name;
  String subname;
  long[] cases;
  float[] labelY;
  String startDate = "";
  PImage logo;
  PGraphics fixedLogo;
  
  int OFFSET = 1;
  
  int FL_W = 180;
  int FL_H = 108;
  public Disease(int i, String input){
    String[] parts = input.split(",");
    name = parts[0];
    subname = parts[0];
    
    startDate = parts[3];
    cases = new long[MAX_LEN];
    
    if(derive){
      int[] preCases = new int[MAX_LEN];
      for(int day = 1; day < MAX_LEN; day++){
        preCases[day] = Integer.parseInt(parts[min(day+OFFSET,parts.length-1)]);
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
        cases[day] = Integer.parseInt(parts[min(day+OFFSET,parts.length-1)]);
        if(i == SPECIAL && expoContinue >= 0 && day >= LAST_DAY+1){
          int added = (int)((cases[day-1]-cases[day-2])*expoContinue);
          cases[day] = cases[day-1]+added;
        }
        if(i < FLAG_N){
          long val = cases[day];
          if(val > maxes[day]){
            maxes[day] = val;
          }
          if(day <= parts.length){
            if(cases[day] > maxesActive[day]){
              maxesActive[day] = cases[day];
            }
          }
          if(day == LAST_DAY && i == SPECIAL){
            for(int da = day; da < min(day+7, MAX_LEN); da++){
              maxesActive[da] = cases[day];
            }
          }
        }
      }
    }
    if(i < FLAG_N){
      int i2 = i;
      if(i == 10) i2 = 7;
      logo = loadImage("img"+i2+".jpg");
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
    }
    labelY = new float[MAX_LEN];
  }
  String nameSection(int t){
    int index = name.indexOf("(");
    if(t == 0){
      return name.substring(0,index-1);
    }else{
      return name.substring(index,name.length());
    }
  }
}
