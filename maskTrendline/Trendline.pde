class Trendline{
  float[] stats = new float[5];
  public Trendline(String s){
    String[] parts = s.split(",");
    for(int i = 0; i < 5; i++){
      stats[i] = Float.parseFloat(parts[i]);
    }
  }
}
