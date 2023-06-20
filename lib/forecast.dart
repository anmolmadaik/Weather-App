class Forecast{
  late DateTime date;
  late double temp;
  late double temp_max;
  late double temp_min;
  late String main;
  late String icon;

  Forecast(DateTime date, double temp, double temp_max, double temp_min, String main, String icon){
    this.date = date;
    this.temp = temp;
    this.temp_max = temp_max;
    this.temp_min = temp_min;
    this.main = main;
    this.icon = icon;
  }
}