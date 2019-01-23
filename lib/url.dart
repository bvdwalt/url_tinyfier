class Url {
  final String shortURL;
  final String longURL;

  Url(this.shortURL, this.longURL);

  Url.fromJson(Map<String, dynamic> json)
      : shortURL = json['short_url'],
        longURL = json['long_url'];

  Map<String, dynamic> toJson() => {
        'short_url': shortURL,
        'long_url': longURL,
      };
}
