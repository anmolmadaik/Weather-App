import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'address.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'weather.dart';
import 'forecast.dart';
import 'dart:convert';
import "dart:math";
import 'package:flutter_spinkit/flutter_spinkit.dart';

String API = "befd8252237b6810711503b9e0f1ca85";

class Home extends StatefulWidget {

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<Address> savedLocations = [];
  int selected = -1;
  Position? current;
  Weather? weather;
  late bool lightMode;
  List<Forecast> forecast_total = [];
  List<Forecast> forecast_daily = [];
  List<Widget> daysForecast = [];
  List<Widget> today = [];

  void init(){
    setState(() {
      daysForecast = [
        Row(
          children: [
            Expanded(
                flex: 2,
                child: Text(
                  "Day",
                  style: TextStyle(
                    color:lightMode ? Colors.grey[800] : Colors.grey[300],
                    fontSize: 14.5,
                  ),
                  textAlign: TextAlign.end,
                )
            ),
            Expanded(
              flex: 2,
              child: Text(
                "Weather",
                style: TextStyle(
                  color: lightMode ? Colors.grey[800] : Colors.grey[300],
                  fontSize: 14.5,
                ),
                //textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "Temperature",
                style: TextStyle(
                  color: lightMode ? Colors.grey[800] : Colors.grey[300],
                  fontSize: 14.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                "Max/Min",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightMode ? Colors.grey[800] : Colors.grey[300],
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.5),
        Divider(color: lightMode ? Colors.grey[350] : Colors.grey[200],thickness: 1),
        SizedBox(height: 2.5),
      ];
      today = [
        Row(
        children: [
          Expanded(
              child: Text(
                "Time",
                style: TextStyle(
                  color: lightMode ? Colors.grey[800] : Colors.grey[300],
                  fontSize: 17.5,
                ),
              )
          ),
          Expanded(
              child: Text(
                "Weather",
                style: TextStyle(
                  color: lightMode ? Colors.grey[800] : Colors.grey[300],
                  fontSize: 17.5,
                ),
              )
          ),
          Expanded(
              child: Text(
                "Temperature",
                style: TextStyle(
                  color: lightMode ? Colors.grey[800] : Colors.grey[300],
                  fontSize: 17.5,
                ),
              )
          ),
        ],
      ),
        SizedBox(height: 2.5),
        Divider(color: lightMode ? Colors.grey[350] : Colors.grey[200],thickness: 1),
        SizedBox(height: 2.5),
      ];
    });
  }

  bool checkAlreadyAdded(Address a){
    a.coorFromPlace();
    if(this.savedLocations.isNotEmpty){
      for(Address k in savedLocations){
        k.coorFromPlace();
        if(k.longi == a.longi && k.lati == a.lati){
          return true;
        }
      }
    }
    return false;
  }


  Future<void> chooseLocation(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/location');
    if(result != null){
      var data = Map<String,String>.from(result as Map);
      print(data);
      Address a = new Address(data["Country"]!, data["State"]!, data["City"]!);
      await a.coorFromPlace();
      bool contains = false;
      if(this.checkAlreadyAdded(a) == true){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location already added")));
      }
      else{
        setState(() {
          savedLocations.add(a);
          selected = savedLocations.indexOf(a);
          getWeather();
        });
      }
    }
  }


  int no_of_locations(){
    return this.savedLocations.length;
  }


  Future<void> findPosition() async{
    bool check;
    check = await Geolocator.isLocationServiceEnabled();
    if(check == false){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enable location to access current weather data of your location")));
      Geolocator.openLocationSettings();
    }
    LocationPermission permission = await Geolocator.checkPermission();
    Position? position = await Geolocator.getLastKnownPosition();
    if(permission == LocationPermission.whileInUse || permission == LocationPermission.always){
      position = await Geolocator.getCurrentPosition();
      print("1. got position");
      print(position);
      await convert(position.latitude, position.longitude);
    }
    else{
      LocationPermission request = await Geolocator.requestPermission();
      if(request == LocationPermission.whileInUse || permission == LocationPermission.always){
        position = await Geolocator.getCurrentPosition();
        print("2. got position");
        print(position);
        convert(position.latitude, position.longitude);
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Need location permission to access current location")));
        Geolocator.openAppSettings();
      }
    }
    // setState(() {
    //   this.current = position;
    // });
  }


  Future<void> convert(double lat, double long) async{
    List<Placemark> place = await placemarkFromCoordinates(lat, long);
    Address a = Address(place[0].country.toString(),place[0].administrativeArea.toString(),place[0].subAdministrativeArea.toString());
    print("${a.city}, ${a.state}, ${a.country}");
    await a.coorFromPlace();
    if(this.checkAlreadyAdded(a) == true){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location already added")));
    }
    else{
      setState(() {
        this.savedLocations.add(a);
        selected = savedLocations.indexOf(a);
      });
    }
  }


  double mean(List<Forecast> temp){
    double sum = 0;
    for(Forecast f in temp){
      sum += f.temp;
    }
    double average = sum/temp.length;
    return average;
  }


  double max(List<Forecast> temp_max){
    double max = temp_max[0].temp_max;
    for(Forecast f in temp_max){
      if(max < f.temp_max){
        max = f.temp_max;
      }
    }
    return max;
  }


  double min(List<Forecast> temp_min){
    double min = temp_min[0].temp_min;
    for(Forecast f in temp_min){
      if(min > f.temp_min){
        min == f.temp_min;
      }
    }
    return min;
  }


  String mode(List<Forecast> forecast){
    List<String> main = [];
    for(Forecast f in forecast){
      main.add(f.main);
    }
    main.sort;
    String most = main[0];
    int index = 0;
    int highest = 0;
    for(int i=0;i<main.length-1;i++){
      if(main[i] != main[i+1]){
        ++index;
        if(index > highest){
          highest = index;
          most = main[i];
        }
        index = 0;
      }
      else{
        ++index;
      }
    }
    return most;
  }

  String modeIcon(List<Forecast> forecast){
    List<String> main = [];
    for(Forecast f in forecast){
      main.add(f.icon);
    }
    main.sort;
    String most = main[0];
    int index = 0;
    int highest = 0;
    for(int i=0;i<main.length-1;i++){
      if(main[i] != main[i+1]){
        ++index;
        if(index > highest){
          highest = index;
          most = main[i];
        }
        index = 0;
      }
      else{
        ++index;
      }
    }
    return most;
  }

  void toDaily(){
    List<Forecast> f = [];
    for(int i=0;i<39;i++) {
      if (forecast_total[i].date.day == forecast_total[i + 1].date.day) {
        f.add(forecast_total[i]);
      }
      else {
        f.add(forecast_total[i]);
        double temp = mean(f);
        double temp_max = max(f);
        double temp_min = min(f);
        String main = mode(f);
        String icon = modeIcon(f);
        Forecast fore = Forecast(f[0].date, temp, temp_max, temp_min, main, icon);
        f.clear();
        setState(() {
          this.forecast_daily.add(fore);
        });
      }
    }
    f.add(forecast_total[39]);
    double temp = mean(f);
    double temp_max = max(f);
    double temp_min = min(f);
    String main = mode(f);
    String icon = modeIcon(f);
    Forecast fore = Forecast(f[0].date,temp,temp_max,temp_min,main, icon);
    f.clear();
    setState(() {
      this.forecast_daily.add(fore);
      for(Forecast fo in forecast_daily){
        print("${day(fo.date.weekday)}, ${fo.main}, ${fo.temp}, ${fo.temp_max}, ${fo.temp_min}");
        this.daysForecast.add(
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(
                      "${day(fo.date.weekday)}",
                      style: TextStyle(
                        color: lightMode ? Colors.black : Colors.white,
                        fontSize: 16,
                      ),
                    )
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Text(
                        fo.main,
                        style: TextStyle(
                          color: lightMode ? Colors.black : Colors.white,
                          fontSize: 16,
                        ),
                        // textAlign: TextAlign.center,
                      ),
                  Image.asset("Icons/${fo.icon}.png",scale: 3),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                      "${fo.temp.toStringAsFixed(2)}°C",
                    style: TextStyle(
                      color: lightMode ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                      "${fo.temp_max.toStringAsFixed(0)}°C/${fo.temp_min.toStringAsFixed(0)}°C",
                    style: TextStyle(
                      color: lightMode ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              ],
            ),

        );
        this.daysForecast.add(SizedBox(height: 2.5));
        this.daysForecast.add(Divider(color: lightMode ? Colors.grey[350] : Colors.grey[200],thickness: 1),);
        this.daysForecast.add(SizedBox(height: 2.5));
      }
      for(Forecast t in this.forecast_total){
        if(t.date.day == DateTime.now().day){
          today.add(
            Row(
              children: [
                Expanded(
                    child: Text(
                      t.date.minute >10 ? "${t.date.hour} : ${t.date.minute}" : "${t.date.hour} : 0${t.date.minute}",
                      style: TextStyle(
                        color: lightMode ? Colors.black : Colors.white,
                        fontSize: 19,
                      ),
                    )
                ),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                          t.main,
                        style: TextStyle(
                          color: lightMode ? Colors.black : Colors.white,
                          fontSize: 19,
                        ),
                      ),
                      Image.asset("Icons/${t.icon}.png",scale: 3,)
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    "${t.temp}°C",
                    style: TextStyle(
                      color: lightMode ? Colors.black : Colors.white,
                      fontSize: 19,
                    ),
                  ),
                ),
              ],
            )
          );
          today.add(SizedBox(height: 2.5));
          today.add(Divider(color: lightMode ? Colors.grey[350] : Colors.grey[200],thickness: 1),);
          today.add(SizedBox(height: 2.5));
        }
      }
    });

  }


  void Empty() async{
    setState(() {
     this.forecast_total.clear();
     this.forecast_daily.clear();
     this.daysForecast.clear();
     this.today.clear();
     init();
    });
  }


  void getWeather() async{
    try {
      weather = null;
      if (selected == -1) {
        await findPosition();
      }
      setState(() {
        Empty();
      });
      print("Weather API started");
      final http.Response response = await http.get(Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?lat=${savedLocations[selected]
              .lati.toString()}&lon=${savedLocations[selected].lati
              .toString()}&appid=${API}&units=metric"));
      print("Weather API finished");
      print("Forecast API started");
      final http.Response response2 = await http.get(Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?lat=${savedLocations[selected]
              .lati.toString()}&lon=${savedLocations[selected].lati
              .toString()}&appid=${API}&units=metric"));
      print("Forecast API finished");
      print(response.body);
      final list = jsonDecode(response.body);
      print(DateTime.fromMillisecondsSinceEpoch(list["dt"] * 1000));
      final forecast = jsonDecode(response2.body);
      //print(forecast);
      //print(list["weather"][0]["icon"]);
      int i = 0;
      for (var f in forecast["list"]) {
        ++i;
        // print(i);
        DateTime d = DateTime.fromMillisecondsSinceEpoch(f["dt"] * 1000);
        // print(d.toLocal());
        // print(f);
        Forecast fore = new Forecast(
            d, f["main"]["temp"].toDouble(), f["main"]["temp_max"].toDouble(),
            f["main"]["temp_min"].toDouble(), f["weather"][0]["main"], f["weather"][0]["icon"]);
        setState(() {
          this.forecast_total.add(fore);
        });
      }
      //print(this.forecast_total);
      // print(list["list"][0]["main"]["temp"]);
      // // var k = list["list"];
      //print(k.length);
      toDaily();
      // print(this.forecast_daily);
      // print(list["weather"][0]["main"]);
      var rain = list["rain"];
      var snow = list["snow"];
      if(rain == null){
        rain = 0;
      }
      else{
        rain = rain["1h"];
      }
      if(snow == null){
        snow = 0;
      }
      else{
        snow = snow["1h"];
      }
      Weather w = new Weather(
          list["weather"][0]["main"],
          list["weather"][0]["description"],
          list["weather"][0]["icon"],
          list["main"]["temp"].toDouble(),
          list["main"]["feels_like"].toDouble(),
          list["main"]["temp_max"].toDouble(),
          list["main"]["temp_min"].toDouble(),
          list["main"]["pressure"],
          list["main"]["humidity"],
          list["visibility"],
          list["wind"]["speed"],
          list["wind"]["deg"],
          list["clouds"]["all"],
          list["sys"]["sunrise"],
          list["sys"]["sunset"],
          rain.toDouble(),
          snow.toDouble()
      );
      // print(w.main);
      // print(w.desc);
      // print(w.icon);
      // print(w.temp);
      // print(w.feels);
      // print(w.temp_max);
      // print(w.temp_min);
      // print(w.pressure);
      // print(w.humidity);
      // print(w.visibility);
      // print(w.windspd);
      // print(w.winddir);
      // print(w.cloud);
      // print(w.rain);
      // print(w.snow);
      // print(w.sunrise);
      // print(w.sunset);
      setState(() {
        this.weather = w;
      });
    }
    catch(e){
      print('error caught: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e"),duration: Duration(seconds: 5),));
    }
  }


  String day(int weekday){
    String day = '';
    switch(weekday){
      case 1: day = "Monday";
      break;
      case 2: day = "Tuesday";
      break;
      case 3: day = "Wednesday";
      break;
      case 4: day = "Thursday";
      break;
      case 5: day = "Friday";
      break;
      case 6: day = "Saturday";
      break;
      case 7: day = "Sunday";
      break;
    }
    return day;
  }

  void checkLightMode(BuildContext context){
    var brightness = MediaQuery.of(context).platformBrightness;
    print(brightness);
    if(brightness == Brightness.light){
      setState(() {
        this.lightMode = true;
      });
    }
    else{
      setState(() {
        this.lightMode = false;
      });
    };
  }

  @override
  void initState(){
   // checkLightMode(context);
    getWeather();
  }


  @override
  Widget build(BuildContext context) {
    checkLightMode(context);
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: lightMode ? Colors.black : Colors.white),
        backgroundColor: lightMode == true ? Colors.white : Colors.black87,
        elevation: 10,
        title: Center(
          child: Text("Weather",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lightMode? Colors.black :Colors.white,
            ),
          ),
        ),
        actions: <Widget> [
          IconButton(onPressed: (){
            chooseLocation(context);
          },
              icon: Icon(Icons.add_location_outlined, color: lightMode ? Colors.black : Colors.white),
          )
        ],
      ),
      drawer: Drawer(
        surfaceTintColor: lightMode? Colors.black : Colors.white,
        child: this.no_of_locations() >0 ?
        Column(
          children: [
            SizedBox(
              height:80,
              child: DrawerHeader(
                  child: Text("Added Locations",
                    style: TextStyle(
                      color: lightMode? Colors.black : Colors.white,
                      fontSize: 20
                    ),
                  ),
              ),
            ),
            Divider(color: lightMode ? Colors.grey[800] : Colors.grey[200], ),
            ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: this.no_of_locations(),
                itemBuilder: (context, index){
                  return Row(
                    //margin: EdgeInsets.symmetric(vertical: 3),
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selected = index;
                              getWeather();
                            });
                          },
                          child: this.savedLocations[index].city == "" ? this.savedLocations[index].state == "" ? Text("${this.savedLocations[index].country}", style: selected == index? TextStyle( fontSize: 18.5, color: lightMode? Colors.black : Colors.white) :TextStyle( fontSize: 17, color: lightMode? Colors.grey[600] : Colors.grey[400]), overflow: TextOverflow.ellipsis,) : Text("${this.savedLocations[index].state}, ${this.savedLocations[index].country}", style: selected == index? TextStyle( fontSize: 18.5, color: lightMode ? Colors.black : Colors.white) : TextStyle( fontSize: 17, color: lightMode? Colors.grey[600] : Colors.grey[350]), overflow: TextOverflow.ellipsis,) : Text("${this.savedLocations[index].city}, ${this.savedLocations[index].state}, ${this.savedLocations[index].country}", style: selected == index? TextStyle( fontSize: 18.5, color: lightMode ? Colors.black : Colors.white) : TextStyle( fontSize: 17, color: lightMode ? Colors.grey[600] : Colors.grey[400]), overflow: TextOverflow.ellipsis,),
                        ),
                    ),]
                  );
                }
            ),
          ],
        )
        :
        Center(
          child: Text("No locations added",
            style: TextStyle(
              color: lightMode ? Colors.grey[500] : Colors.grey[400],
              fontSize: 15
            ),
          ),
        ),
      ),
      body: no_of_locations() == 0 ?
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Tap ",style: TextStyle(fontSize: 16, color: lightMode ? Colors.grey[600] : Colors.grey[350]),),
                Icon(Icons.add_location_outlined, color: lightMode ? Colors.grey[600] : Colors.grey[350]),
                Text(" to add a location", style: TextStyle(fontSize: 16, color: lightMode ? Colors.grey[600] : Colors.grey[350]))
              ],
            )
          ):
          selected == -1 || weather == null ?
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitRing(
                  size: 50,
                  color: lightMode ? Colors.black45 : Colors.white70,
                ),
                SizedBox(height: 15),
                Text("Fetching Weather Data",
                  style: TextStyle(
                    color: lightMode ? Colors.black54 : Colors.white70,
                    fontSize: 18
                  ),
                )
              ],
            ),
          )
          :
          Container(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 3,
                    child:
                      Padding(
                          padding: EdgeInsets.fromLTRB(50, 40, 50, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      savedLocations[selected].city == "" ? savedLocations[selected].state == "" ? savedLocations[selected].country : "${savedLocations[selected].state}, ${savedLocations[selected].country}" : "${savedLocations[selected].city}, ${savedLocations[selected].state}, ${savedLocations[selected].country}",
                                      style: TextStyle(
                                        color: lightMode ? Colors.grey[700] : Colors.grey[300],
                                        fontSize: 20
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset("Icons/${weather!.icon}.png",),
                                        Text(
                                          this.weather!.main,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 40,
                                            color: lightMode ? Colors.black : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(color: lightMode ? Colors.grey[300] : Colors.grey[200], thickness: 1),
                                    SizedBox(height: 10),
                                    Text(
                                      this.weather!.desc,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: lightMode ? Colors.grey[800] : Colors.grey[200]
                                      ),
                                    ),
                                    SizedBox(height: 7),
                                    Divider(color: lightMode ? Colors.grey[300] : Colors.grey[200], thickness: 1),
                                    SizedBox(height: 0),
                                   ExpansionTile(
                                     title: Text("Today weather",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: lightMode ? Colors.grey[600] : Colors.grey[200]
                                          ),
                                       textAlign: TextAlign.start,
                                     ),

                                     children:
                                     [
                                       SizedBox(height: 10),
                                       Column(
                                         children:
                                         this.forecast_daily.length == 6 ?
                                         today:
                                         [Text("Today's weather data not available", style: TextStyle(color: lightMode ? Colors.black : Colors.grey[200]))],
                                        ),
                                     ]
                                   )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                       ),
                     SizedBox(height: 20),
                     Card(
                       elevation: 3,
                       child: Padding(
                         padding: EdgeInsets.symmetric(vertical: 40, horizontal: 50),
                         child: Column(
                           children: [
                             IntrinsicHeight(
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                                 children: [
                                   Expanded(
                                     flex: 1,
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Text("Temperature",
                                           style: TextStyle(
                                             color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                             fontSize: 20
                                           ),
                                         ),
                                         Text(
                                           this.weather!.temp.toString(),
                                           style: TextStyle(
                                               color: lightMode ? Colors.black : Colors.white,
                                               fontSize: 35
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                   VerticalDivider(color:  lightMode ? Colors.grey[300] : Colors.grey[200], thickness :1),
                                   Expanded(
                                     flex: 1,
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Text("Feels like",
                                           style: TextStyle(
                                               color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                               fontSize: 20
                                           ),
                                         ),
                                         Text(
                                           this.weather!.feels.toString(),
                                           style: TextStyle(
                                               color: lightMode ? Colors.black : Colors.white,
                                               fontSize: 35
                                           ),
                                         )
                                       ],
                                     ),
                                   )
                                 ],
                               ),
                             ),
                             SizedBox(height: 3),
                             Divider(color:  lightMode ? Colors.grey[300] : Colors.grey[200], thickness: 1),
                             SizedBox(height: 3),
                             IntrinsicHeight(
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Expanded(
                                     flex: 1,
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Text("Maximum",
                                           style: TextStyle(
                                               color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                               fontSize: 20
                                           ),
                                         ),
                                         Text(
                                           this.weather!.temp_max.toString(),
                                           style: TextStyle(
                                               color: lightMode ? Colors.black : Colors.white,
                                               fontSize: 35
                                           ),
                                         )
                                       ],
                                     ),
                                   ),
                                   VerticalDivider(thickness: 1, color: lightMode ? Colors.grey[300] : Colors.grey[200]),
                                   Expanded(
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                          Text("Minimum",
                                            style: TextStyle(
                                                color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                                fontSize: 20
                                            ),
                                          ),
                                         Text(
                                           this.weather!.temp_min.toString(),
                                           style: TextStyle(
                                               color: lightMode ? Colors.black : Colors.white,
                                               fontSize: 35
                                           ),
                                         )
                                       ],
                                     ),
                                   )
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                  SizedBox(height: 22.5),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(5, 20, 5, 10),
                      child: Column(
                        children: this.daysForecast,
                      ),
                    )
                  ),
                  SizedBox(height: 22.5),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Pressure",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                          fontSize: 20
                                        ),
                                      ),
                                      Image.asset("Icons/pressure.png", height: 27.5, width: 50,)
                                    ],
                                  )
                              ),
                              Expanded(
                                  flex: 1,
                                  child: Text(
                                   "${this.weather!.pressure.toString()} hPa",
                                   textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: lightMode ? Colors.black : Colors.white,
                                        fontSize: 20
                                    ),
                                  ),
                              )
                            ],
                          ),
                          SizedBox(height: 5),
                          Divider(color: lightMode ? Colors.grey[300] : Colors.grey[200], thickness: 1),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Humidity",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                            fontSize: 20
                                        ),
                                      ),
                                      Image.asset("Icons/humidity.png", height: 27.5, width: 50,)
                                    ],
                                  )
                              ),
                              Expanded(
                                  flex: 1,
                                  child: Text(
                                    "${this.weather!.humidity.toString()}%",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: lightMode ? Colors.black : Colors.white,
                                        fontSize: 20
                                    ),
                                  )
                              )
                            ],
                          ),
                          SizedBox(height: 5),
                          Divider(color: lightMode ? Colors.grey[300] : Colors.grey[200], thickness: 1),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Visibility",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                            fontSize: 20
                                        ),
                                      ),
                                      Image.asset("Icons/visibility.png", height: 27.5, width: 50,)
                                    ],
                                  )
                              ),
                              Expanded(
                                  flex: 1,
                                  child: Text(
                                    "${this.weather!.visibility.toString()}m",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: lightMode ? Colors.black : Colors.white,
                                        fontSize: 20
                                    ),
                                  )
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 22.5),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Cloud",
                                        style: TextStyle(
                                          fontSize: 19.5,
                                          color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                        ),
                                      ),
                                      Image.asset("Icons/04d.png",scale: 2)
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "${this.weather!.cloud.toString()}%",
                                    style: TextStyle(
                                      fontSize: 19.5,
                                      color: lightMode ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            ),
                            VerticalDivider(thickness: 1, color: lightMode ? Colors.grey[350] : Colors.grey[200]),
                            Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Rain",
                                          style: TextStyle(
                                            fontSize: 19.5,
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                          ),
                                        ),
                                        Image.asset("Icons/09d.png",scale: 2)
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                        "${this.weather!.rain.toString()} mm",
                                      style: TextStyle(
                                        fontSize: 19.5,
                                        color: lightMode ? Colors.black : Colors.white,
                                      ),
                                    )
                                  ],
                                )
                            ),
                            VerticalDivider(thickness: 1, color: lightMode ? Colors.grey[350] : Colors.grey[200]),
                            Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Snow",
                                          style: TextStyle(
                                            fontSize: 19.5,
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                          ),
                                        ),
                                        Image.asset("Icons/13d.png",scale: 2)
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                        "${this.weather!.snow.toString()} mm",
                                      style: TextStyle(
                                        fontSize: 19.5,
                                        color: lightMode ? Colors.black : Colors.white,
                                      ),
                                    )
                                  ],
                                )
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.5,),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                                flex:1,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Wind Speed",
                                          style: TextStyle(
                                            fontSize: 19.5,
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                          ),
                                        ),
                                        Image.asset("Icons/windspd.png", height: 27.5, width: 50,)
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "${this.weather!.windspd.toString()} m/s",
                                      style: TextStyle(
                                        fontSize: 19.5,
                                        color: lightMode ? Colors.black : Colors.white,
                                      ),
                                    )
                                  ],
                                )
                            ),
                            VerticalDivider(thickness: 1, color: lightMode ? Colors.grey[350] : Colors.grey[200]),
                            Expanded(
                                flex:1,
                                child: Column(
                                  children: [
                                    Row(
                                     // mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Wind Direction",
                                          style: TextStyle(
                                            fontSize: 19.5,
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                          ),
                                        ),
                                        Image.asset("Icons/winddir.png", height: 27.5, width: 35,)
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "${this.weather!.winddir.toString()}°",
                                      style: TextStyle(
                                        fontSize: 19.5,
                                        color: lightMode ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.5,),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Sunrise",
                                        style: TextStyle(
                                          color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                          fontSize: 20,
                                        ),
                                      ),
                                      Image.asset("Icons/sunrise.png", height: 27.5, width: 50,)
                                    ],
                                  ),
                                  Text(
                                    this.weather!.sunrise.minute > 10 ? "${this.weather!.sunrise.hour} : ${this.weather!.sunrise.minute}" : "${this.weather!.sunrise.hour} : 0${this.weather!.sunrise.minute}",
                                    style: TextStyle(
                                      color: lightMode ? Colors.black : Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              )
                            ),
                            VerticalDivider(thickness: 1, color: lightMode ? Colors.grey[350] : Colors.grey[200]),
                            Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Sunset",
                                          style: TextStyle(
                                            color: lightMode ? Colors.grey[800] : Colors.grey[300],
                                            fontSize: 20,
                                          ),
                                        ),
                                        Image.asset("Icons/sunset.png", height: 27.5, width: 50,)
                                      ],
                                    ),
                                    Text(
                                      this.weather!.sunset.minute > 10 ? "${this.weather!.sunset.hour} : ${this.weather!.sunset.minute}" : "${this.weather!.sunset.hour} : 0${this.weather!.sunset.minute}",
                                      style: TextStyle(
                                        color: lightMode ? Colors.black : Colors.white,
                                        fontSize: 20,
                                      ),
                                    )
                                  ],
                                )
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
