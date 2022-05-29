import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:FlutterMobilenet/services/tensorflow-service.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

GlobalKey previewContainer = new GlobalKey();
var feedbackImage;
var feedbackLabel;

_insertCockroach(image, label) async {
  try {
    var connection = PostgreSQLConnection(dotenv.env["COCKROACHDB_HOST"], 26257,
        dotenv.env["COCKROACHDB_DATABASE"],
        username: dotenv.env["COCKROACHDB_USER"],
        password: dotenv.env["COCKROACHDB_PASSWORD"],
        useSSL: true,
        allowClearTextPassword: true);
    await connection.open();
    print("Connected to CockroachDB!");

    var result = await connection.query(
        "INSERT INTO public.feedback (imagebytes, label) VALUES (@a, @b)",
        substitutionValues: {"a": feedbackImage, "b": feedbackLabel});
    print('Feedback inserted in CockroachDB!');
  } catch (e) {
    print(e);
  }
}

class Recognition extends StatefulWidget {
  Recognition({Key key, @required this.ready}) : super(key: key);

  // indicates if the animation is finished to start streaming (for better performance)
  final bool ready;

  @override
  _RecognitionState createState() => _RecognitionState();
}

// to track the subscription state during the lifecicle of the component
enum SubscriptionState { Active, Done }

class _RecognitionState extends State<Recognition> {
  // current list of recognition
  List<dynamic> _currentRecognition = [];

  static const url = 'https://flutter.io';
  String first_class = '';
  double first_class_confidence = 0;
  String onFlip = '';
  String capitalize(String first_class) =>
      first_class[0].toUpperCase() + first_class.substring(1);

  // listens the changes in tensorflow recognitions
  StreamSubscription _streamSubscription;

  // tensorflow service injection
  TensorflowService _tensorflowService = TensorflowService();

  @override
  void initState() {
    super.initState();

    // starts the streaming to tensorflow results
    _startRecognitionStreaming();
  }

  _startRecognitionStreaming() {
    if (_streamSubscription == null) {
      _streamSubscription =
          _tensorflowService.recognitionStream.listen((recognition) {
        if (recognition != null) {
          // rebuilds the screen with the new recognitions
          setState(() {
            _currentRecognition = recognition;

            first_class = capitalize(recognition[0]['label']);
            if (first_class == 'Plastic_bags' ||
                first_class == 'Plastic_brik' ||
                first_class == 'Plastic_bottles') {
              first_class = 'Plastic';
            } else if (first_class == 'Computer' ||
                first_class == "Microwave") {
              first_class = 'Electronics';
            }
            first_class_confidence = recognition[0]['confidence'];
          });
        } else {
          _currentRecognition = [];
          first_class = 'Searching...';
        }
      });
    }
  }

  _launchURL() async {
    const url = 'https://flutter.io';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _launchCamera() async {
    const url = 'https://flutter.io';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _takeScreenShot() async {
    RenderRepaintBoundary boundary =
        previewContainer.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    final directory = (await getApplicationDocumentsDirectory()).path;
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);
    File imgFile = new File('$directory/screenshot.png');
    feedbackImage = pngBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: RepaintBoundary(
          key: previewContainer,
          child: Container(
            height: 230,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlipCard(
                    front: Container(
                      decoration: BoxDecoration(
                        color: getColor(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 200,
                      width: MediaQuery.of(context).size.width - 30,
                      child: Column(
                        children: widget.ready
                            ? <Widget>[
                                // shows recognition title
                                _titleWidget(),

                                // shows recognitions list
                                _contentWidget(),
                              ]
                            : <Widget>[],
                      ),
                    ),
                    back: Container(
                        decoration: BoxDecoration(
                          color: getColor(),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 200,
                        width: MediaQuery.of(context).size.width - 30,
                        padding: EdgeInsets.only(top: 15, left: 10, right: 40),
                        child: Column(
                          children: widget.ready
                              ? <Widget>[
                                  // shows recognition title
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                        "Wrong classification? Feedback!",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w200)),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: new IconButton(
                                      icon: new Icon(
                                        Icons.camera_alt,
                                        size: 50,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        _takeScreenShot();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SecondRoute()),
                                        );
                                      },
                                    ),
                                  ),

                                  new Container(
                                    padding: EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      0,
                                    ),
                                    // shows recognitions list

                                    child: Text(
                                        "You are reducing the co2 in the planet. It's time for change!",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w300)),
                                  ),
                                ]
                              : <Widget>[],
                        ))),
              ],
            ),
          )),
    );
  }

  Widget _titleWidget() {
    return Container(
      padding: EdgeInsets.only(top: 15, left: 20, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            first_class,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }

  getImage() {
    if (first_class == "Plastic") {
      return "assets/images/amarillo.png";
    } else if (first_class == "Paper" || first_class == "Cardboard") {
      return "assets/images/papel.png";
    } else if (first_class == "Glass") {
      return "assets/images/verde.png";
    } else if (first_class == "Batteries") {
      return "assets/images/contenedorPilas.png";
    } else if (first_class == "Waste") {
      return "assets/images/organico.png";
    } else if (first_class == "Electronics") {
      return "assets/images/localWasteFacility.png";
    } else {
      return "assets/images/organico.png";
    }
    //es probable que haya que meter un else para que no pete
  }

  getLabel() {
    if (first_class == "Plastic") {
      return "Yellow container";
    } else if (first_class == "Paper" || first_class == "Cardboard") {
      return "Blue container";
    } else if (first_class == "Glass") {
      return "Green container";
    } else if (first_class == "Batteries") {
      return "Battery container";
    } else if (first_class == "Waste") {
      return "Brown container";
    } else if (first_class == "Electronics") {
      return "Local facility";
    } else {
      return "Brown container";
    }
  }

  getColor() {
    if (first_class == "Plastic") {
      return Color.fromARGB(255, 170, 177, 69);
    } else if (first_class == "Paper" || first_class == "Cardboard") {
      return Color.fromARGB(255, 69, 128, 177);
    } else if (first_class == "Glass") {
      return Color.fromARGB(255, 69, 177, 101);
    } else if (first_class == "Batteries") {
      return Color.fromARGB(255, 241, 146, 36);
    } else if (first_class == "Waste") {
      return Color.fromARGB(255, 197, 140, 53);
      ;
    } else if (first_class == "Electronics") {
      return Color.fromARGB(255, 138, 132, 124);
    } else {
      return Color.fromARGB(255, 197, 140, 53);
    }
  }

  getFilter() {
    if (first_class_confidence * 100 >= 40.0) {
      return first_class_confidence;
    } else {
      return '';
    }
  }

  _insertCockroach() async {
    try {
      var connection = PostgreSQLConnection(dotenv.env["COCKROACHDB_HOST"],
          26257, dotenv.env["COCKROACHDB_DATABASE"],
          username: dotenv.env["COCKROACHDB_USER"],
          password: dotenv.env["COCKROACHDB_PASSWORD"],
          useSSL: true,
          allowClearTextPassword: true);
      await connection.open();
      print("Connected to CockroachDB!");
    } catch (e) {
      print(e);
    }
  }

  Widget _contentWidget() {
    var _width = MediaQuery.of(context).size.width;
    var _padding = 20.0;
    var _labelWitdth = 150.0;
    var _labelConfidence = 30.0;
    var _barWitdth = _width - _labelWitdth - _labelConfidence - _padding * 2.0;

    if (_currentRecognition.length > 0) {
      return Container(
        height: 150,
        child: ListView.builder(
          itemCount: 1, //se pone uno para que no saque más de una etiqueta
          itemBuilder: (context, index) {
            if (first_class.length > index) {
              return Container(
                height: 40,
                child: Row(
                  children: <Widget>[
                    Container(
                        padding:
                            EdgeInsets.only(left: _padding, right: _padding),
                        width: _labelWitdth,
                        child: Image.asset(
                          getImage(),
                          width: 120,
                          height: 120,
                        )
                        /*Text(
                        _currentRecognition[index]['label'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      */
                        ),
                    Container(
                      width: _barWitdth,
                      child: Text(
                        getLabel(),
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w300),
                      ),
                      //to debug: Text(getLabel() + " " +(getFilter() * 100).toString() + '%', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w300),),
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      );
    } else {
      return Text('');
    }
  }

  Widget _infoWidget() {
    var _width = MediaQuery.of(context).size.width;
    var _padding = 20.0;
    var _labelWitdth = 150.0;
    var _labelConfidence = 30.0;
    var _barWitdth = _width - _labelWitdth - _labelConfidence - _padding * 2.0;

    if (_currentRecognition.length > 0) {
      return Container(
        height: 150,
        child: ListView.builder(
          itemCount: 1, //se pone uno para que no saque más de una etiqueta
          itemBuilder: (context, index) {
            if (first_class.length > index) {
              return Container(
                height: 40,
                child: Row(
                  children: <Widget>[
                    Container(
                        padding:
                            EdgeInsets.only(left: _padding, right: _padding),
                        width: _labelWitdth,
                        child: Image.asset(
                          getImage(),
                          width: 40,
                          height: 40,
                        )
                        /*Text(
                        _currentRecognition[index]['label'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      */
                        ),
                    Container(
                      width: _barWitdth,
                      child: Text(
                        getLabel() + " " + (getFilter() * 100).toString() + '%',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w300),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      );
    } else {
      return Text('');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

class SecondRoute extends StatelessWidget {
  const SecondRoute();

  showAlertDialog(BuildContext context) {
    // set up the button

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Thank you!"),
      content: Text(
          "Your object photo has been sent successfully. \n\nThank you for the feedback"),
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reporting object'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Center(
        child: new Column(
          children: [
            new Container(
                padding: EdgeInsets.fromLTRB(25, 100, 25, 20),
                child: Image(
                  image: AssetImage('assets/images/recycle.gif'),
                  height: 160,
                  width: 160,
                )),
            new Container(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 25),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Go Back!",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w300)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green.shade600,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(20.0),
                        ),
                      ),
                    ))),
            new Container(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 25),
                    child: ElevatedButton(
                      onPressed: () {
                        _insertCockroach(feedbackImage, feedbackLabel);
                        Navigator.pop(context);
                        showAlertDialog(context);
                      },
                      child: Text("Send",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w300)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green.shade600,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(20.0),
                        ),
                      ),
                    ))),
            new Container(
                padding: EdgeInsets.fromLTRB(25, 25, 25, 25),
                child: MyStatefulWidget()),
          ],
        ),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  String dropdownValue = 'Yellow container';

  @override
  Widget build(BuildContext context) {
    feedbackLabel = dropdownValue;
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(
          color: Color.fromARGB(255, 67, 160, 71),
          fontSize: 19,
          fontWeight: FontWeight.w300),
      underline: Container(
        height: 2,
        color: Colors.green.shade600,
      ),
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
        });
      },
      items: <String>[
        'Yellow container',
        'Green container',
        'Blue container',
        'Brown container',
        'Local facility'
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
