class County{
  String name;
  int pop;
  float mask;
  float[] cases = new float[DAY_LEN];
  PGraphics stateImage;
  color col;
  public County(String s, int i){
    String[] parts = s.split(",");
    name = cleanName(parts[0]);
    pop = Integer.parseInt(parts[1]);
    mask = Float.parseFloat(parts[2]);
    for(int p = 0; p < parts.length-3; p++){
      cases[p] = Float.parseFloat(parts[p+3]);
      if(cases[p] > maxes[p]){
        maxes[p] = cases[p];
      }
    }
    if(!COUNTY_MODE){
      stateImage = getStateImage(i);
    }
    
    colorMode(HSB,1);
    col = color(random(0,1),0.43,1.0);
    colorMode(RGB,255);
  }
  PGraphics getStateImage(int preI){
    int i = preI;
    if(preI == 44){
      i = 18;
    }else if(preI == 8){
      i = 51;
    }else if(preI >= 9 && preI <= 18){
      i = preI-1;
    }else if(preI >= 19 && preI <= 39){
      i = preI;
    }else if(preI >= 40 && preI <= 43){
      i = preI-1;
    }else if(preI >= 45 && preI <= 48){
      i = preI-2;
    }else if(preI >= 49){
      i = preI-3;
    }
    int x = i%7;
    int y = i/7;
    PGraphics img = createGraphics(61,61);
    img.beginDraw();
    img.image(stateShapes,-x*64-1,-y*64-1);
    //img.fill(255,255,255,128);
    //img.noStroke();
    //img.rect(0,0,63,63);
    img.endDraw();
    return img;
  }
  float getCases(float day){
    int dayInt = (int)day;
    float before = cases[dayInt];
    float after = cases[min(dayInt+1,DAY_LEN-1)];
    float prog = day%1.0;
    return before+(after-before)*prog;
  }
  String cleanName(String n){
    if(COUNTY_MODE){
      return n.replace(";",", ");
    }else{
      String result = n;
      String[][] re = {{"North","N"}, {"South","S"}, {"New","N"}, {"District of Columbia","DC"}};
      for(int i = 0; i < re.length; i++){
        result = result.replace(re[i][0],re[i][1]);
      }
      return result;
    }
  }
}
