class Url {
  final String shortURL;
  final String longURL;

  Url(this.shortURL, this.longURL);

  Url.fromJson(Map<String, dynamic> json)
      : shortURL = json['shortURL'],
        longURL = json['longURL'];

  Map<String, dynamic> toJson() => {
        'shortURL': shortURL,
        'longURL': longURL,
      };
}
