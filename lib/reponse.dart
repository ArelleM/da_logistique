
// Reponse après POST

// mapping de la classe Reponse pour récupérer une architecture similaire au json reçu
class Reponse {
  var alert;
  String title;
  Data data;
  Show show;

  Reponse(Map json,this.alert,this.title,this.data,this.show);

  Reponse.fromJson(Map json) {
    alert = json["alert"];
    title = json["title"] as String;
    // class data
    data = Data.fromJson(json["data"]);
    // class show
    show = Show.fromJson(json["show"]);
  }

}

// mapping class data
class Data {
  var qr_code_001;
  var qr_code_002;
  var qr_code_003;
  var qt;
  var condi;
  var dluo;
  var lot;
  var zone;
  var confirm;
  var url_pdf;
  var zebra;

  Data({
    this.qr_code_001,
    this.qr_code_002,
    this.qr_code_003,
    this.qt,
    this.condi,
    this.dluo,
    this.lot,
    this.zone,
    this.confirm,
    this.url_pdf,
    this.zebra
  });

  Data.fromJson(Map json) {
    qr_code_001 = json["qr_code_001"];
    qr_code_002 = json["qr_code_002"];
    qr_code_003 = json["qr_code_003"];
    qt = json["qt"];
    condi = json["condi"];
    dluo = json["dluo"];
    lot = json["lot"];
    zone = json["zone"];
    confirm = json["confirm"];
    url_pdf = json["url_pdf"] as String;
    zebra = Zebra.fromJson(json["zebra"]);
  }


}

// mapping class show
class Show {
  bool qr_code_001;
  bool qt;
  bool dluo;
  bool lot;
  bool zone;
  bool confirm;
  bool photo;
  bool submit;
  bool print;

  Show({
    this.qr_code_001,
    this.qt,
    this.dluo,
    this.lot,
    this.zone,
    this.confirm,
    this.photo,
    this.submit,
    this.print,
  });

  Show.fromJson(Map json) {
    qr_code_001 = json["qr_code_001"] as bool;
    qt = json["qt"] as bool;
    dluo = json["dluo"] as bool;
    lot = json["lot"] as bool;
    zone = json["zone"] as bool;
    confirm = json["confirm"] as bool;
    photo = json["reserve"] as bool;
    submit = json["submit"] as bool;
    print = json["print"] as bool;
  }


}
// mapping class show
class Zebra {
  var zpl;

  Zebra({
    this.zpl,
  });

  Zebra.fromJson(Map json) {
    zpl = json["ZPL"];
  }


}
