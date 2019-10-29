import 'package:flutter/material.dart';
import './url.dart';

class UrlListItem extends StatelessWidget {
  final Url url;

  UrlListItem(this.url);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(children: [
        Expanded(
            child: Column(children: [
          Text(
            url.shortURL,
            textScaleFactor: 2,
            textAlign: TextAlign.left,
          ),
          Text(
            url.longURL,
            textScaleFactor: 1,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ], crossAxisAlignment: CrossAxisAlignment.start)),
      ]),
    );
  }
}
