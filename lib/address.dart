import 'package:geocoding/geocoding.dart';

class Address{
  late String country;
  late String state;
  late String city;

  late double lati;
  late double longi;

  Address(String c, String s, String ct){
    this.country = c;
    this.state = s;
    this.city = ct;
  }

  Future<void> coorFromPlace() async {
    List<Location> locations = await locationFromAddress("${this.city}, ${this.state}, ${this.country}");
    this.lati = locations[0].latitude;
    this.longi = locations[0].longitude;
  }
}