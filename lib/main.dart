import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './url.dart';
import './UrlListItem.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Tinyfier',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
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
  List<Url> _listItems = new List();
  bool _loading = false;
  BuildContext _scaffoldContext;

  void _addNewListItem(Url url) {
    setState(() {
      _listItems.add(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = new Scaffold(
      body: _loading ? new  Center(child: new CircularProgressIndicator(value: null)) : new ListView.builder(
          itemCount: _listItems.length,
          itemBuilder: (BuildContext ctxt, int index) {
            var item = _listItems[index];
            return GestureDetector(
              child: UrlListItem(item),
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
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new Scaffold(
          appBar: new AppBar(title: new Text('Add a new short URL')),
          body: new TextField(
            autofocus: true,
            onSubmitted: (val) {
              if (val == '') {
                return;
              }
              _fetchData(val);
              Navigator.pop(context);
            },
            decoration: new InputDecoration(
                hintText: 'Enter the url you want to shorten...',
                contentPadding: const EdgeInsets.all(16.0)),
          ));
    }));
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
