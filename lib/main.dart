import 'dart:io';
import 'dart:ui' as ui;
import 'colors.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(
  MaterialApp(
    title: 'Face Recognition',
    debugShowCheckedModeBanner: false,
    home: FacePage(),
  ),
);

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image;

  _getImageAndDetectFaces() async {
    final _picker = ImagePicker();
    final pickedFile = await _picker.getImage(
        source: ImageSource.gallery
    );
    final File imageFile = File(pickedFile.path);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(
            mode: FaceDetectorMode.fast,
            enableLandmarks: true
        )
    );
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
          (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        centerTitle: true,
        actions: [],
        backgroundColor: primaryDark.withOpacity(0.8),
        title: Text(
          'Face Detection',
          style: TextStyle(color: textColor),
        ),
      ),
      body: isLoading
          ? Container(
          height: MediaQuery
              .of(context)
              .size
              .height,
          width: MediaQuery
              .of(context)
              .size
              .width,
          child: Center(child: CircularProgressIndicator(backgroundColor: primaryColor,),),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.4),
          ),)
          : (_imageFile == null)
          ? Container(
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width,
        child: Center(child: Text(
          'Select an Image',
          style: TextStyle(
              fontSize: 20, color: textColor,fontWeight: FontWeight.bold),
        ),),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.4),
        ),)
          : Container(
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.4),
        ),
            child: Center(
        child: FittedBox(
            child: SizedBox(
              width: _image.width.toDouble(),
              height: _image.height.toDouble(),
              child: CustomPaint(
                painter: FacePainter(_image, _faces),
              ),
            ),
        ),
      ),
          ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.image,
          color: primaryDark,
        ),
        backgroundColor: textColor,
        onPressed: _getImageAndDetectFaces,
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = primaryColor;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}