import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final String imageUrl;
  final String userName;
  final AnimationController animationController;

  ChatMessage(
      {String text,
      String imageUrl,
      String userName,
      AnimationController animationController})
      : text = text,
        imageUrl = imageUrl,
        userName = userName,
        animationController = animationController;

  Map<String, dynamic> toMap() {
    return {'text': text, 'username': userName};
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        sizeFactor:
            CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(child: Text(userName[0])),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(userName, style: Theme.of(context).textTheme.subhead),
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
