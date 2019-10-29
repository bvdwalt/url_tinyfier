import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import './UrlListItem.dart';
import './url.dart';

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
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Url> _listItems = List<Url>();
  final String membershipKey = 'url_tinyfier_urls';
  SharedPreferences _storage;
  bool _loading = false;
  BuildContext _scaffoldContext;

  @override
  Widget build(BuildContext context) {
    Widget body = Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator(value: null))
          : ListView.builder(
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
                              title: const Text('Confirm'),
                              content: const Text(
                                  'Are you sure you wish to delete this item?'),
                              actions: <Widget>[
                                FlatButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('DELETE')),
                                FlatButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('CANCEL'),
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
                            content: Text(item.shortURL + ' removed'), backgroundColor: Theme.of(context).colorScheme.primary,));
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
      body: Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return body;
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadListFromStorage();
  }

  void _addNewListItem(Url url) {
    setState(() {
      _listItems.add(url);
    });
    _updateListInStorage();
  }

  void _copyToClipboard(Url item) {
    Clipboard.setData(ClipboardData(text: item.shortURL));
    Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
      content: Text('Copied to Clipboard'),
      duration: Duration(seconds: 3),
    ));
  }

  Future<bool> _fetchData(String longUrl) async {
    setState(() {
      _loading = true;
    });
    final http.Response response =
        await http.get('https://tinyurl.com/api-create.php?url=' + longUrl);
    if (response.statusCode == 200) {
      _addNewListItem(Url(response.body, longUrl));
      setState(() {
        _loading = false;
      });
    } else {
      throw Exception('Failed to load');
    }
    return response.statusCode == 200;
  }

  void _launchURL(Url url) async {
    if (await canLaunch(url.shortURL)) {
      await launch(url.shortURL);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _loadListFromStorage() async {
    _storage = await SharedPreferences.getInstance();
    setState(() {
      _listItems = List();
      json
          .decode(_storage.getString(membershipKey))
          .forEach((Map<String, dynamic> map) => _listItems.add(Url.fromJson(map)));
    });
  }

  void _pushAddURLScreen() {
    if (!_loading) {
      Navigator.of(context).push<MaterialPageRoute>(MaterialPageRoute(builder: (context) {
        return Scaffold(
            appBar: AppBar(title: Text('Add a new short URL')),
            body: Form(
              autovalidate: true,
              child: TextFormField(
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

  void _removeListItemAt(int index) {
    setState(() {
      _listItems.removeAt(index);
    });
    _updateListInStorage();
  }

  void _updateListInStorage() async {
    _storage.setString(membershipKey, json.encode(_listItems));
  }

  String _validateNewLongURL(String value) {
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
}
