//import 'dart:html';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';



class TimeLinePage extends StatefulWidget {
  final User gCurrentUser;
  TimeLinePage({this.gCurrentUser});
  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}





class _TimeLinePageState extends State<TimeLinePage> {
  List<Post> posts;
  List<String> followingsList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  retrieveTimeLine() async
  {
    QuerySnapshot querySnapshot = await timeLineReference.doc(widget.gCurrentUser.id)
        .collection("timeLinePosts").orderBy("timestamp", descending: true ).get();
    List<Post> allPosts = querySnapshot.docs.map((document) => Post.fromDocument(document)).toList();
    setState(() {
      this.posts = allPosts;
    });
  }

  retrieveFollowings()async
  {
    QuerySnapshot querySnapshot = await followersReference.doc(currentUsr.id)
        .collection("userFollowing").get();
    setState(() {
      followingsList = querySnapshot.docs.map((document) => document.id).toList();
    });
  }

  @override
  void initState(){
    super.initState();
    retrieveTimeLine();
    retrieveFollowings();
  }

  createTimeLine(){
  if(posts == null)
    {
      return circularProgress();
    }
  else
    {
      return ListView(children: posts,);
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: header(context, isAppTitle: true),
      body:  RefreshIndicator(child: createTimeLine(), onRefresh: ()=> retrieveTimeLine()),
    );
  }
}
