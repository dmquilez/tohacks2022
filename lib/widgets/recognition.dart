import 'dart:async';
import 'package:FlutterMobilenet/services/tensorflow-service.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';


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

  String first_class = '';

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
      _streamSubscription = _tensorflowService.recognitionStream.listen((recognition) {
        if (recognition != null) {
          // rebuilds the screen with the new recognitions
          setState(() {
            _currentRecognition = recognition;

            first_class = recognition[0]['label'];
            
          });
        } else {
          _currentRecognition = [];
          first_class = 'Searching...';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 230,
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlipCard(front: Container(
                
                decoration: BoxDecoration(
                  color: Color(0xFF120320),
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
              ), back: Container(
                padding: EdgeInsets.only(top: 15, left: 20, right: 10),
                child: Text("Web Page", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 201, 162, 238),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 200,
                width: MediaQuery.of(context).size.width - 30,
                
                
    )),
          ],
        ),
      ),
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

  getImage(){
    if(first_class == "plastic"){
      return "assets/images/amarillo.png";
    }else if(first_class == "paper"){
      return "assets/images/papel.png";
    }else{
      return "assets/images/ropa.png";
    }
  }

  getLabel(){
    if(first_class == "plastic"){
      return "Yellow Container";
    }else if(first_class == "paper"){
      return "Blue Container";
    }else{
      return "ropa";
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
          itemCount: 1,//se pone uno para que no saque más de una etiqueta
          itemBuilder: (context, index) {
            if (first_class.length > index) {
              return Container(
                height: 40,
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: _padding, right: _padding),
                      width: _labelWitdth,
                      child: Image.asset(getLabel(),
                      width: 50,
                      height: 50,)
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
                        "Yellow container",
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
