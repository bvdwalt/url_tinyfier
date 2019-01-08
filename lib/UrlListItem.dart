import 'package:flutter/material.dart';
import './url.dart';

class UrlListItem extends StatelessWidget {
  final Url url;

  UrlListItem(this.url);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.all(16.0),
      child: new Row(children: [
        new Expanded(
            child: new Column(children: [
          new Text(
            url.shortURL,
            textScaleFactor: 3,
            textAlign: TextAlign.left,
          ),
          new Text(
            url.longURL,
            textScaleFactor: 1,
            textAlign: TextAlign.right,
            style: new TextStyle(
              color: Colors.grey,
            ),
          ),
        ], crossAxisAlignment: CrossAxisAlignment.start)),
      ]),
    );
  }
}
