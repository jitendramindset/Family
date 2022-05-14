//import 'dart:html';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/EditProfilePage.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/PostTileWidget.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String userProfileID;
  ProfilePage({this.userProfileID});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String currentOnlineUserId = currentUsr?.id;
  bool loading = false;
  int countPost = 0;
  List<Post> postsList = [];
  String postOrientation = "grid";
  int countTotalFollowings = 0;
  int countTotalFollowers = 0;
  bool following = false;
  void initState() {
    getAllProfilePosts();
    getAllFollowers();
    getAllFollowings();
    checkIfAlreadyFollowing();
  }

  getAllFollowings()async
  {
    QuerySnapshot querySnapshot = await followingReference.doc(widget.userProfileID)
        .collection("userFollowing").get();
    setState(() {
      countTotalFollowings = querySnapshot.docs.length;
    });
  }
  checkIfAlreadyFollowing() async
  {
    DocumentSnapshot documentSnapshot = await followersReference
        .doc(widget.userProfileID).collection("userFollowers")
        .doc(currentOnlineUserId).get();
    setState(() {
      following = documentSnapshot.exists;
    });
  }

  getAllFollowers()async{
    QuerySnapshot querySnapshot = await followersReference.doc(widget.userProfileID)
        .collection("userFollowers").get();
    setState(() {
      countTotalFollowers = querySnapshot.docs.length;
    });
  }

  createProfileTopView() {
    return FutureBuilder(
      future: usersReference.doc(widget.userProfileID).get(),
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        return Padding(
          padding: EdgeInsets.all(17.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 45.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.url),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              createColumns("Posts", countPost),
                              createColumns("Followers", countTotalFollowers),
                              createColumns("Following", countTotalFollowings),
                            ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            createButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 13.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 5.0),
                child: Text(
                  user.profileName,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 18.0),
                child: Text(
                  user.bio,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Column createColumns(String title, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5.0),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
                fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  createButton() {
    bool ownProfile = currentOnlineUserId == widget.userProfileID;
    if (ownProfile) {
      return createButtonTitleAndFunction(
        title: "Edit Profile",
        performFunction: editUserProfile,
      );
    }
    else if (following) {
      return createButtonTitleAndFunction(
        title: "UnFollow",
        performFunction: controlUnfollowUser,
      );
    }
    else if (!following) {
      return createButtonTitleAndFunction(
        title: "Follow",
        performFunction: controlFollowUser,
      );
    }
  }
  controlUnfollowUser(){
    setState(() {
      following = false;
    });
    followersReference.doc(widget.userProfileID).collection("userFollowers")
    .doc(currentOnlineUserId).get()
    .then((document){
     document.reference.delete();
    });
    followingReference.doc(currentOnlineUserId).collection("userFollowing")
        .doc(widget.userProfileID).get()
        .then((document){
      document.reference.delete();
    });

    activityFeedReference.doc(widget.userProfileID).collection("feedItems")
    .doc(currentOnlineUserId).get().then((document){
      document.reference.delete();
    });
  }
  createButtonTitleAndFunction({String title, Function performFunction}) {
    return Container(
      padding: EdgeInsets.only(top: 3.0),
      child: FlatButton(
        onPressed: performFunction,
        child: Container(
          width: 200.0,
          height: 26.0,
          child: Text(
            title,
            style: TextStyle(color: following? Colors.grey: Colors.white, fontWeight: FontWeight.bold),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: following? Colors.black : Colors.green,
              border: Border.all(color:
              following? Colors.grey : Colors.white),
              borderRadius: BorderRadius.circular(6.0)),
        ),
      ),
    );
  }

  controlFollowUser(){
    setState(() {
      following = true;
    });

    followersReference.doc(widget.userProfileID).collection("userFollowers")
    .doc(currentOnlineUserId)
    .set({});

    followingReference.doc(currentOnlineUserId).collection("userFollowing")
        .doc(widget.userProfileID)
        .set({});

    activityFeedReference.doc(widget.userProfileID).collection("feedItems")
    .doc(currentOnlineUserId)
    .set({
      "type": "follow",
      "ownerId": widget.userProfileID,
      "username": currentUsr.username,
      "timestamp": DateTime.now(),
      "userProfileImg":currentUsr.url,
      "userId": currentOnlineUserId,
    });
  }
  editUserProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditProfilePage(currentOnlineUserId: currentOnlineUserId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Profile"),
      body: ListView(
        children: <Widget>[
          createProfileTopView(),
          Divider(),
          createListAndGridPostOrientation(),
          Divider(
            height: 0.0,
          ),
          displayProfilePost(),
        ],
      ),
    );
  }

  displayProfilePost() {
    if (loading) {
      return circularProgress();
    } else if (postsList.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(30.0),
              child: Icon(
                Icons.photo_library,
                color: Colors.grey,
                size: 200.0,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 40.0,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTilesList = [];
      postsList.forEach((eachPost) {
        gridTilesList.add(GridTile(
          child: PostTile(eachPost),
        ));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTilesList,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: postsList,
      );
    }
  }

  getAllProfilePosts() async {
    setState(() {
      loading = true;
    });
    QuerySnapshot querySnapshot = await postsReference
        .doc(widget.userProfileID)
        .collection("usersPosts")
        .orderBy("timestamp", descending: true)
        .get();
    setState(() {
      loading = false;
      countPost = querySnapshot.docs.length;
      postsList = querySnapshot.docs.map((documentSnapshot) => Post.fromDocument(documentSnapshot)).toList();
    });
  }

  createListAndGridPostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid"
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == "list"
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  setOrientation(String orientation) {
    setState(() {
      this.postOrientation = orientation;
    });
  }
}
