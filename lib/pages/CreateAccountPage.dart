import 'dart:async';

import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String userName;
  submitUsername(){
    final form = _formKey.currentState;
    if(form.validate()){
      form.save();
      SnackBar snackBar = SnackBar(content: Text("Welcome" + userName),);
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 4),(){
        Navigator.pop(context ,userName);
      });
    }
  }
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, strTitle: "Setting", disableBackButton: true),
    body: ListView(
      children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 26.0),
                child: Center(
                  child: Text("Set Up a Username",
                  style: TextStyle(
                    fontSize: 26.0
                  ),),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(17.0),
                child: Container(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.always,
                    child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      validator:(val){
                        if(val.trim().length<5 || val.isEmpty){
                          return "Invalid User Name";
                        }
                        else if( val.trim().length > 15){
                          return "User name is vary long";
                        }
                        else{
                          return null;
                        }
                      },
                      onSaved: (val) => userName = val,
                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:  BorderSide( color: Colors.white),
                        ),
                        border: OutlineInputBorder(),
                        labelText: "UserName",
                        labelStyle: TextStyle(fontSize: 16.0),
                        hintText: "UserName Should be between 5 to 15 Characters",
                        hintStyle:  TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ),
              ),
              GestureDetector(
                onTap: submitUsername,
                child: Container(
                  height: 55.0,
                  width: 369.0,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular( 8.0),
                    ),
                  child: Center(
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    ),
    );
  }
}
