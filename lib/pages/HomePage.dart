import 'dart:io';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/CreateAccountPage.dart';
import 'package:buddiesgram/pages/NotificationsPage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/pages/SearchPage.dart';
import 'package:buddiesgram/pages/TimeLinePage.dart';
import 'package:buddiesgram/pages/UploadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final usersReference = FirebaseFirestore.instance.collection("users");
final FirebaseStorage  storageReference = FirebaseStorage.instance.ref().child("Posts Pictures");
final postsReference = FirebaseFirestore.instance.collection("Posts");
final activityFeedReference = FirebaseFirestore.instance.collection("feed");
final commentsReference = FirebaseFirestore.instance.collection("comments");
final followersReference = FirebaseFirestore.instance.collection("followers");
final followingReference = FirebaseFirestore.instance.collection("following");
final timeLineReference = FirebaseFirestore.instance.collection("timeLine");

final DateTime timestamp = DateTime.now();
User currentUsr;
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0;
  FirebaseMessaging _firebaseMessaging =  FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void initState() {
    super.initState();
    pageController = PageController();
    gSignIn.onCurrentUserChanged.listen((gSignInAccount) {
      controlSignIN(gSignInAccount);
    }, onError: (gError) {
      print("error" + gError);
    });
//    if close app or rerun emulater then check old signin
    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount) {
      controlSignIN(gSignInAccount);
    }).catchError((gError) {
      print("Error Message" + gError);
    });
  }

  controlSignIN(GoogleSignInAccount gSignInAccount) async {
    if (isSignedIn != null) {
      await saveUSerInfoToFireStore();
      setState(() {
        isSignedIn = true;
      });

      configureRealTimePushNotifications();
    } else {
      setState(() {
        isSignedIn = false;
      });
    }
  }

  configureRealTimePushNotifications()
  {
    final GoogleSignInAccount gUser = gSignIn.currentUser;
    if(Platform.isIOS)
      {
        getIOSPermissions();
      }
    _firebaseMessaging.getToken().then((token){
      usersReference.doc(gUser.id).update({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> msg) async
        {
          final String recipientId = msg["data"] ["recipient"];
          final String body = msg["notification"] ["body"];
          if(recipientId == gUser.id)
            {
              SnackBar snackBar =SnackBar(
                backgroundColor: Colors.grey,
                  content: Text(body,style: TextStyle(color: Colors.black),
                  overflow: TextOverflow.ellipsis,),
              );
              _scaffoldKey.currentState.showSnackBar(snackBar);
            }

        }
    );
  }

  getIOSPermissions()
  {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound:  true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings Registered:  $settings");
    });
  }

  saveUSerInfoToFireStore() async{
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await usersReference.doc(gCurrentUser.id).get();
    if(!documentSnapshot.exists){
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context)=> CreateAccountPage()));

    usersReference.doc(gCurrentUser.id).set({
      "id": gCurrentUser.id,
      "profileName":gCurrentUser.displayName,
      "username": username,
      "url": gCurrentUser.photoUrl,
      "email": gCurrentUser.email,
      "bio":"",
      "timestamp": timestamp,
    });
    
    await followersReference.doc(gCurrentUser.id)
      .collection("userFollowers").doc(gCurrentUser.id)
      .set({});
    documentSnapshot = await usersReference.doc(gCurrentUser.id).get();
    }
    currentUsr = User.fromDocument(documentSnapshot);
  }
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  loginUser() {
    gSignIn.signIn();
  }

  logoutUser() {
    gSignIn.signOut();
  }

  whenPageChanges(int pageIndex) {
    setState(() {
      this.getPageIndex = pageIndex;
    });
  }

  onTapChangePage(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(microseconds: 400), curve: Curves.bounceInOut);
  }

//  Widget buildHomeScreen(){
//    return RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close), label: Text("Sign Out"));
//  }
  Scaffold buildHomeScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUsr),
//          RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close), label: Text("Sign Out")),
          SearchPage(),
          UploadPage(gCurrentUser: currentUsr),
          NotificationsPage(),
          ProfilePage(userProfileID: currentUsr.id),
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: getPageIndex,
        onTap: onTapChangePage,
        activeColor: Colors.red,
        inactiveColor: Colors.white, //blueGrey,
        backgroundColor: Theme.of(context).accentColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 31.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.favorite)),
          BottomNavigationBarItem(icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  Scaffold buildSignINScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Theme.of(context).accentColor,
            Theme.of(context).primaryColor
          ],
        )),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Gotra',
              style: TextStyle(
                  fontSize: 92.0, color: Colors.red, fontFamily: "Signatra"),
            ),
            GestureDetector(
              onTap: loginUser,
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage("assets/images/google_signin_button.png"),
                  fit: BoxFit.cover,
                )),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSignedIn) {
      return buildHomeScreen();
    } else {
      return buildSignINScreen();
    }
  }
}
