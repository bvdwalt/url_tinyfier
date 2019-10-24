import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './url.dart';
import './UrlListItem.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Tinyfier',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(title: 'URL Tinyfier'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Url> _listItems = new List<Url>();
  final String membershipKey = 'url_tinyfier_urls';
  SharedPreferences _storage;
  bool _loading = false;
  BuildContext _scaffoldContext;

  @override
  void initState() {
    super.initState();
    _loadListFromStorage();
  }

  void _loadListFromStorage() async {
    _storage = await SharedPreferences.getInstance();
    setState(() {
      _listItems = new List();
      json
          .decode(_storage.getString(membershipKey))
          .forEach((map) => _listItems.add(new Url.fromJson(map)));
    });
  }

  void _updateListInStorage() async {
    _storage.setString(membershipKey, json.encode(_listItems));
  }

  void _addNewListItem(Url url) {
    setState(() {
      _listItems.add(url);
    });
    _updateListInStorage();
  }

  void _removeListItemAt(int index) {
    setState(() {
      _listItems.removeAt(index);
    });
    _updateListInStorage();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = new Scaffold(
      body: _loading
          ? new Center(child: new CircularProgressIndicator(value: null))
          : new ListView.builder(
              itemCount: _listItems?.length ?? 0,
              itemBuilder: (BuildContext ctxt, int index) {
                var item = _listItems[index];
                return GestureDetector(
                  child: Dismissible(
                      key: Key(item.shortURL),
                      background: Container(color: Colors.red),
                      confirmDismiss: (DismissDirection direction) async {
                        final bool res = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm"),
                              content: const Text(
                                  "Are you sure you wish to delete this item?"),
                              actions: <Widget>[
                                FlatButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("DELETE")),
                                FlatButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("CANCEL"),
                                ),
                              ],
                            );
                          },
                        );

                        return res;
                      },
                      onDismissed: (direction) {
                        _removeListItemAt(index);
                        Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
                            content: Text(item.shortURL + " removed")));
                      },
                      child: UrlListItem(item)),
                  onTap: () => _launchURL(item),
                  onLongPress: () => _copyToClipboard(item),
                );
              }),
      resizeToAvoidBottomPadding: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _pushAddURLScreen,
        tooltip: 'Add New',
        child: Icon(Icons.add),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return body;
      }),
    );
  }

  void _copyToClipboard(Url item) {
    Clipboard.setData(new ClipboardData(text: item.shortURL));
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(
      content: new Text('Copied to Clipboard'),
      duration: new Duration(seconds: 3),
    ));
  }

  void _pushAddURLScreen() {
    if (!_loading) {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new Scaffold(
            appBar: new AppBar(title: new Text('Add a new short URL')),
            body: new Form(
              autovalidate: true,
              child: new TextFormField(
                autofocus: true,
                decoration: const InputDecoration(
                  icon: Icon(Icons.link),
                  hintText: 'Enter the URL you would like to shorten',
                  labelText: 'URL: *',
                ),
                initialValue: 'https://',
                onFieldSubmitted: (String value) {
                  if (_validateNewLongURL(value) != null) {
                    return;
                  }
                  _fetchData(value);
                  Navigator.pop(context);
                },
                validator: (String value) => _validateNewLongURL(value),
                keyboardType: TextInputType.url,
              ),
            ));
      }));
    }
  }

  _validateNewLongURL(String value) {
    if (value == '') {
      return 'Please enter a URL to shorten';
    } else if (!value.contains('https://') && !value.contains('http://')) {
      return 'Kindly pre-fix your URL with either "https://" or "http://"';
    } else {
      value = value.replaceFirst("https://", "");
      value = value.replaceFirst("http://", "");
      if (value == '') {
        return 'Kindly enter a URL to shorten';
      }
    }
    return null;
  }

  _fetchData(String longUrl) async {
    setState(() {
      _loading = true;
    });
    final response =
        await http.get("https://tinyurl.com/api-create.php?url=" + longUrl);
    if (response.statusCode == 200) {
      _addNewListItem(new Url(response.body, longUrl));
      setState(() {
        _loading = false;
      });
    } else {
      throw Exception('Failed to load');
    }
  }

  void _launchURL(Url url) async {
    if (await canLaunch(url.shortURL)) {
      await launch(url.shortURL);
    } else {
      throw 'Could not launch $url';
    }
  }
}
