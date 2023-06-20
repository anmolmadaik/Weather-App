import 'dart:core';

class Weather{
  late String main;
  late String desc;
  late String icon;
  late double temp;
  late double feels;
  late double temp_max;
  late double temp_min;
  late int pressure;
  late int humidity;
  late int visibility;
  late double windspd;
  late int winddir;
  late int cloud;
  late double rain;
  late double snow;
  late DateTime sunrise;
  late DateTime sunset;

  Weather(String main, String desc, String icon,double temp, double feels, double temp_max, double temp_min, int pressure, int humidity, int visibility, double windspd, int winddir, int cloud, int sunrise, int sunset,
      double rain, double snow){
    this.main= main;
    String result = desc[0].toUpperCase();
    for(int i=1;i<desc.length;i++){
      if(desc[i-1] == " "){
        result = result + desc[i].toUpperCase();
      }
      else{
        result = result + desc[i];
      }
    }
    this.desc = result;
    this.icon = icon;
    this.temp = temp;
    this.feels = feels;
    this.temp_max = temp_max;
    this.temp_min = temp_min;
    this.pressure = pressure;
    this.humidity = humidity;
    this.visibility = visibility;
    this.windspd = windspd;
    this.winddir = winddir;
    this.cloud = cloud;
    this.rain = rain;
    this.snow = snow;
    this.sunrise = DateTime.fromMillisecondsSinceEpoch(sunrise * 1000).toLocal();
    this.sunset = DateTime.fromMillisecondsSinceEpoch(sunset * 1000).toLocal();
  }
}