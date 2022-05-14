//import 'dart:html';
import 'dart:io';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as ImD;

class UploadPage extends StatefulWidget {
  final User gCurrentUser;
  UploadPage({this.gCurrentUser});
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> with AutomaticKeepAliveClientMixin<UploadPage> {

    File file;
    bool uploading = false;
    String postId = Uuid().v4();
    TextEditingController descriptionTextEditingController = TextEditingController();
    TextEditingController locationTextEditingController = TextEditingController();

    captureImageFromCamera() async{
    Navigator.pop(context);
//    PickedFile imagefile = await ImagePicker().getImage(
//      source: ImageSource.camera,
//      maxHeight: 600,
//      maxWidth: 970,
//    );
      File imagefile = File(await ImagePicker().getImage(source: ImageSource.gallery,
      maxHeight: 600,
      maxWidth: 970,
      ).then((pickedFile) => pickedFile.path));
    setState(() {
      this.file = imagefile;
    });
  }

    pickImageFromGallery()async{
    Navigator.pop(context);
    File imagefile = File(await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxHeight: 600,
      maxWidth: 970,
    ).then((pickedFile) => pickedFile.path));
    setState(() {
      this.file = imagefile;
    });
    }

  takeImage(mcontext){
    return showDialog(
        context: mcontext,
    builder: (context){
      return SimpleDialog(
        title: Text(
          "New Post",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: <Widget>[
          SimpleDialogOption(
            child: Text("Capture Image With Camera",
              style: TextStyle(
                color: Colors.white,

              ),),
            onPressed: captureImageFromCamera,
          ),
          SimpleDialogOption(
            child: Text("Select Image From Gallery",
              style: TextStyle(
                color: Colors.white,

              ),),
            onPressed: pickImageFromGallery,
          ),
          SimpleDialogOption(
            child: Text("Cancel",
              style: TextStyle(
                color: Colors.white,

              ),),
            onPressed: (){Navigator.pop(context);}
          ),
        ],
      );
    },
    );
  }

  displayUploadScreen(){
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.add_photo_alternate,
            color: Colors.red,
            size: 200.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.0),),
              child: Text("Upload Image",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),),
              color: Colors.red,
              onPressed:()=> takeImage(context),
            ),
          ),
        ],
      ),
    );
  }
    clearPostInfo(){
      locationTextEditingController.clear();
      descriptionTextEditingController.clear();
    setState(() {
      file = null;
    });
    }
    getCurrentLocation()async{
      Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark mplacemark = placemark[0];
      String completAddressInfo ='${mplacemark.subThoroughfare} ${mplacemark.thoroughfare},${mplacemark.subLocality} ${mplacemark.locality},${mplacemark.subAdministrativeArea} ${mplacemark.administrativeArea},${mplacemark.postalCode} ${mplacemark.country}';
      String specificAddress = '${mplacemark.locality}, ${mplacemark.country}';
      locationTextEditingController.text = specificAddress;
    }

    compressingPhoto()async{
      final tDirectory = await getTemporaryDirectory();
      final path = tDirectory.path;
      ImD.Image mImageFile = ImD.decodeImage(file.readAsBytesSync());
      final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality: 60));
      setState(() {
        file = compressedImageFile;
      });
    }

    controlUploadAndSave()async{
      setState(() {
        uploading = true;
      });
      await compressingPhoto();

      String downloadUrl =  await uploadPhoto(file);

      savePostInfoToFireStore(url: downloadUrl, location: locationTextEditingController.text, description: descriptionTextEditingController.text);

      locationTextEditingController.clear();
      descriptionTextEditingController.clear();
      setState(() {
        file = null;
        uploading = false;
        postId = Uuid().v4();
      });
    }

    savePostInfoToFireStore({String url , String location, String description} ){
      postsReference.doc(widget.gCurrentUser.id).collection("usersPosts").doc(postId).setData({
        "postId": postId,
        "ownerId": widget.gCurrentUser.id,
        "timestamp": DateTime.now(),
        "likes": {},
        "username": widget.gCurrentUser.username,
        "location": location,
        "description": description,
        "url": url,
      });
    }

    Future<String> uploadPhoto(mImageFile)async{
    StorageUploadTask mStorageUploadTask = storageReference.child("post_$postId.jpg").putFile(mImageFile);
    StorageTaskSnapshot storageTaskSnapshot = await mStorageUploadTask.onComplete;
    String downloadUrl =  await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
    }

    displayUploadFromScreen(){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
          color: Colors.white,),
          onPressed: clearPostInfo
        ),
        title: Text("New Post",
        style: TextStyle(
          fontSize: 24.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: uploading ? null : ()=> controlUploadAndSave(),
            child: Text("Share",
            style: TextStyle(
              color: Colors.lightGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16.0
            ),),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Container(
            height: 230.0,
              width: MediaQuery.of(context).size.width * 08,
            child:
            Center(
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(
                          file
                      ),
                      fit: BoxFit.cover,
                    )
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider( widget.gCurrentUser.url),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: descriptionTextEditingController,
                decoration: InputDecoration(
                  hintText: "Say Something about image",
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 36.0,
              ),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  color: Colors.white,
                ),
                controller: locationTextEditingController,
                decoration: InputDecoration(
                  hintText: "add location for image",
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 220.0,
            height: 110.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(35.0)),
              color: Colors.grey,
              icon: Icon(Icons.location_on, color: Colors.white,),
              label: Text("Get my current Location",
              style: TextStyle(color: Colors.white),),
              onPressed: getCurrentLocation,
            ),
          ),
        ],
      ),
    );
    }

    bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return  file  == null ? displayUploadScreen() : displayUploadFromScreen();
  }
}
