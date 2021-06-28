class Country{
  String name;
  int population;
  int[] cases;
  int[] deaths;
  double[] smoothedCases;
  double[] smoothedDeaths;
  int continent;
  public Country(String s, String cont){
    String[] parts = s.split("\t");
    name = parts[0];
    population = Integer.parseInt(parts[1]);
    cases = commaSeparate(parts[2]);
    deaths = commaSeparate(parts[4]);
    smoothedCases = smoothArray(cases);
    smoothedDeaths = smoothArray(deaths);
    continent = strToCont(cont);
    
    for(int d = 0; d < DAY_LEN; d++){
      if(smoothedCases[d] >= 0){
        casesWorld[d] += smoothedCases[d];
      }
      if(smoothedDeaths[d] >= 0){
        deathsWorld[d] += smoothedDeaths[d];
      }
    }
  }
  int strToCont(String cont){
    String contShort = cont.split("\t")[1];
    for(int i = 0; i < CONTINENT_NAMES.length; i++){
      if(contShort.equals(CONTINENT_NAMES[i])){
        return i;
      }
    }
    return 0;
  }
  double getCPC(double day){
    return getAV(day,smoothedCases,population);
  }
  double getDPC(double day){
    return getAV(day,smoothedDeaths,population);
  }
  void drawCountry(double d){
    float x = casesToX(getCPC(d));
    float y = deathsToY(getDPC(d));
    float r = popToR(population);
    pushMatrix();
    translate(x,y);
    if(vidCountry.equals(name)){
      fill(0);
    }else{
      fill(CONTINENT_COLORS[continent]);
    }
    ellipse(0,0,r,r);
    if(vidCountry.length() == 0 || vidCountry.equals(name)){
      float fSize = min(max(sqrt(population)/110,13),24);
      textFont(fontBig,fSize);
      textAlign(CENTER);
      text(capitalize(name),0,-r-6);
    }
    popMatrix();
  }
}
