import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:friendlychat/model/chat_message.dart';
import 'package:friendlychat/service/authentication.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen(String title, {Key key, this.auth, this.userId, this.onSignedOut})
      : _title = title,
        super(key: key);

  final _title;
  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State createState() => ChatScreenState(_title);
}

const List<Choice> choices = const <Choice>[
  const Choice('Sign out'),
  const Choice('Settings')
];

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _title;
  final List<ChatMessage> _messages;
  final TextEditingController _textController;
  final DatabaseReference _messageDatabaseReference;
  final StorageReference _photoStorageReference;

  bool _isComposing = false;

  ChatScreenState(String title)
      : _title = title,
        _isComposing = false,
        _messages = <ChatMessage>[],
        _textController = TextEditingController(),
        _messageDatabaseReference =
            FirebaseDatabase.instance.reference().child("messages"),
        _photoStorageReference =
            FirebaseStorage.instance.ref().child("chat_photos") {
    _messageDatabaseReference.onChildAdded.listen(_onMessageAdded);
  }

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _textController,
                  onChanged: (String text) {
                    setState(() {
                      _isComposing = text.length > 0;
                    });
                  },
                  onSubmitted: _handleSubmitted,
                  decoration:
                      InputDecoration.collapsed(hintText: "Send a message"),
                ),
              ),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.camera_alt), onPressed: _sendImage),
                      Theme.of(context).platform == TargetPlatform.iOS
                          ? CupertinoButton(
                              child: Text("Send"),
                              onPressed: _isComposing
                                  ? () => _handleSubmitted(_textController.text)
                                  : null,
                            )
                          : IconButton(
                              icon: Icon(Icons.send),
                              onPressed: _isComposing
                                  ? () => _handleSubmitted(_textController.text)
                                  : null,
                            ),
                    ],
                  ))
            ],
          ),
        ));
  }

  void _onMessageAdded(Event event) {
    ChatMessage message = createMessage(event.snapshot.value["text"]);
    setState(() {
      _messages.insert(0, message);
    });
    message.animationController.forward();
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    _messageDatabaseReference.push().set(createMessage(text).toMap());
  }

  void _sendImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.camera);
    _photoStorageReference.putFile(image);
  }

  ChatMessage createMessage(String text) {
    return ChatMessage(
      text,
      AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
        ],
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => _messages[index],
                itemCount: _messages.length,
              ),
            ),
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
          ],
        ),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
                border: Border(
                top: BorderSide(color: Colors.grey[200]),
              ))
            : null,
      ),
    );
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    super.dispose();
  }

  void _select(Choice choice) {
    switch (choice.title) {
      case 'Sign out':
        _signOut();
        break;
    }
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }
}

class Choice {
  const Choice(this.title);

  final String title;
}
