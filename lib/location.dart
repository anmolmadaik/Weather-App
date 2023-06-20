import 'package:flutter/material.dart';
import 'package:csc_picker/csc_picker.dart';
import 'address.dart';

class Location extends StatefulWidget {
  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  
  late bool lightMode;

  Map<String,String> location = {
    "Country" : "",
    "State" : "",
    "City": ""
  };

  bool allFilled(String c){
    if(c!=""){
      return true;
    }
    else{
      return false;
    }
  }

  void isLightMode(){
    var brightness = MediaQuery.of(context).platformBrightness;
    if(brightness == Brightness.light){
      setState(() {
        this.lightMode = true;
      });
    }
    else{
      setState(() {
        this.lightMode = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    isLightMode();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightMode ? Colors.white : Colors.black,
        iconTheme: IconThemeData(color: lightMode ? Colors.black : Colors.white),
        elevation: 10,
        title: Center(
          child: Text("Select Location",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lightMode ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              margin: EdgeInsets.symmetric(vertical: 8),
              child: CSCPicker(
                dropdownDecoration: BoxDecoration(
                  color: lightMode ? Colors.white : Colors.black,
                ),
                disabledDropdownDecoration: BoxDecoration(
                    color: lightMode ? Colors.grey[200]: Colors.grey[800]
                ),
                // selectedItemStyle: TextStyle(
                //   color: lightMode ? Colors.black : Colors.white
                // ),
                // dropdownHeadingStyle: TextStyle(
                //     color: lightMode ? Colors.black : Colors.white
                // ),
                // dropdownItemStyle: TextStyle(
                //     color: lightMode ? Colors.black : Colors.white
                // ),
                flagState: CountryFlag.DISABLE,
                onCountryChanged: (value){
                  setState(() {
                    this.location["Country"] = value;
                  });
                },
                onStateChanged: (value){
                  setState(() {
                    this.location["State"] = value??"";
                  });
                },
                onCityChanged: (value){
                  setState(() {
                    this.location["City"] = value??"";
                  });
                },
              )
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                      style: ButtonStyle(
                          backgroundColor: lightMode ? MaterialStatePropertyAll<Color>(Colors.grey.shade200) :  MaterialStatePropertyAll<Color>(Colors.grey.shade800),
                          padding: MaterialStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.symmetric(vertical: 5, horizontal: 10)),
                          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)
                              )
                          )
                      ),
                      onPressed: allFilled(this.location["Country"]!)?
                      (){
                        Navigator.pop(context, this.location);
                      }:
                      null,
                      child: Text(
                        "Confirm Location",
                        style: TextStyle(
                          color: allFilled(this.location["Country"]!)? lightMode ? Colors.black : Colors.white: Colors.grey,
                          fontSize: 14
                        ),
                      )
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
