import 'package:flutter/material.dart';

class CameraHeader extends StatelessWidget {
  const CameraHeader({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        minimum: EdgeInsets.only(top: 45),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/images/recycle.gif'),
              height: 80,
              width: 80,
            ),
          ],
        ),
      ),
    );
  }
}
