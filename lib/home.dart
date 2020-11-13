import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/style.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'reponse.dart';
import 'package:camera/camera.dart';
import 'take_picture.dart';
import 'package:crypto/crypto.dart';
import 'package:printing/printing.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';



class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  SocketIO socket;
  bool isLoading = false;
  OtaEvent currentEvent;
  String _path = null;
  String alert;
  String result = "";
  Reponse reponse;
  bool connected;
  bool start;
  var title;
  bool _visible = true;
  String qrCode1Value;
  String qrCode2Value;
  String qrCode3Value;
  FocusNode myFocusNode;
  var qrCode1Controller = TextEditingController(text: "");
  var qTController = TextEditingController(text: "");
  var dluoController = TextEditingController(text: "");
  var nLotController = TextEditingController(text: "");
  var zoneController = TextEditingController(text: "");
  var motifController = TextEditingController(text: "");
  int condi = 3;
  final _scaffoldKey = GlobalKey<ScaffoldState>();



  @override
  void initState() {
    reponse?.title = "";
    reponse?.alert = "";
    reponse?.data?.qr_code_001 = "";
    reponse?.data?.qr_code_002 = "";
    reponse?.data?.qr_code_003 = "";
    reponse?.data?.confirm = 0;
    reponse?.data?.condi = 3;
    reponse?.data?.zone = "";
    reponse?.data?.qt = 0;
    reponse?.data?.dluo = "";
    reponse?.data?.url_pdf = "";
    super.initState();
    myFocusNode = FocusNode();
    myFocusNode.addListener(() {
      if (!myFocusNode.hasFocus) {
        _makeFormPostRequest();
        qrCode1Controller = TextEditingController(text: "");
      }
      else return "";
    });
    start = true;
  }


  Future<void> tryOtaUpdate() async {
    try {
      //LINK CONTAINS APK OF FLUTTER HELLO WORLD FROM FLUTTER SDK EXAMPLES
      OtaUpdate()
          .execute(
        'https://cantalfret.proxipause.eu/app-release.apk',
        destinationFilename: 'app-release.apk',
      )
          .listen(
            (OtaEvent event) {
          setState(() => currentEvent = event);
        },
      );
    } catch (e) {
      print('Failed to make OTA update. Details: $e');
    }
  }

  // Permet de vérifier si le PDA est connecté à internet
  void isConnected() async{
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          connected = true;
        });

      }
    } on SocketException catch (_) {
      setState(() {
        connected = false;
      });
    }
  }

  // Reset les valeurs des champs Textfield
  void _resetOnPost() async {

    setState(() {
      qrCode1Controller = TextEditingController(text: "");
      qTController = TextEditingController(text: "");
      dluoController = TextEditingController(text: "");
      nLotController = TextEditingController(text: "");
      zoneController = TextEditingController(text: "");
      motifController = TextEditingController(text: "");
      isLoading = false;
    });
  }

  // Remise à zéro des valeurs reçues ( icone maison)
  void _resetDataSend() async {
    setState(() {
      isLoading = false;
      reponse?.title = "";
      reponse?.alert = "";
      reponse?.data?.qr_code_001 = "";
      reponse?.data?.qr_code_002 = "";
      reponse?.data?.qr_code_003 = "";
      reponse?.data?.confirm = 0;
      reponse?.data?.condi = 3;
      reponse?.data?.zone = "";
      reponse?.data?.qt = 0;
      reponse?.data?.dluo = "";
      reponse?.data?.url_pdf = "";
      reponse?.show?.qr_code_001 = true;
      reponse?.show?.confirm = false;
      reponse?.show?.dluo = false;
      reponse?.show?.zone = false;
      reponse?.show?.photo = false;
      start = true;
      reponse?.show?.qt = false;
      reponse?.show?.print = false;
      reponse?.show?.submit = false;
      reponse?.show?.lot = false;
      qrCode1Value = "";
      _path = "";
    });
  }


// Cache le champ alerte au bout de 3 secondes
  _toggle() async {
    await new Future.delayed(const Duration(seconds : 3));
    setState(() {
      _visible = !_visible;
    });
    return _visible;
  }

  // lance l'impression d'une étiquette en pdf
  Future _print() async{





       List<String> printList = reponse?.data?.zebra?.zpl;
    for (var l in printList) {
      Socket socket = await Socket.connect('192.168.1.76', 9100);
      print('connected');
      socket.listen((List<int> event) {
        print(utf8.decode(event));
      });

      // send zpl data
      socket.add(utf8.encode(l));
      // wait 5 seconds
      await Future.delayed(Duration(seconds: 5));

      // .. and close the socket
      socket.close();
    }
    // listen to the received data event stream
/*    socket.listen((List<int> event) {
      print(utf8.decode(event));
    });

    // send zpl data
    socket.add(utf8.encode(reponse?.data?.zebra?.zpl));*/





  }




  // Lance l'appareil photo
  void _showCamera() async {

    final cameras = await availableCameras();
    final camera = cameras.first;

    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePicturePage(camera: camera)));

    setState(() {
      _path = result;
    });
  }

  //Affiche un modal pour arreter l'appli ou non a l'appui du bouton back
  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Etes vous sur?'),
        content: new Text("Voulez vous arreter l'appli?"),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('Non'),
          ),
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: new Text('Oui'),
          ),
        ],
      ),
    )) ?? false;
  }

  // Structure de l'appli
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          //Bouton qui reset les valeurs envoyées et reçues
            leading: IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Redémarrer',
              onPressed: () {
                _resetDataSend();
              },
            ),
            centerTitle: true,
            actions: <Widget>[
              // Lance la mise à jour de l'application en arrière plan, puis l'installation
              IconButton(
                icon: const Icon(Icons.update),
                tooltip: 'Mise a jour',
                onPressed: () {
                  tryOtaUpdate();
                },
              ),
            ]),
        //AlertDialogue pour quitter l'appli
        body:WillPopScope(
            onWillPop: _onWillPop,
            child: ListView(
              shrinkWrap: true,
              children: [
                connected == false ?
                // Si on n'est pas connecté à internet, affiche le message
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text("Vous n'êtes pas connecté a internet"),
                )
                    : Container(),
                isLoading == true?
                // Si l'envoi de donnée est en cours, affiche une animation de chargement
                Center(
                    child:Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator()
                    )
                ):
                reponse?.show?.confirm == true ?
                //Si on reçoit confirm = true, affiche un AlertDialog nous demandant si on doit confirmer ou non l'entrée des données
                AlertDialog(
                  content: Html(data: "${reponse.title}<br>${reponse.alert}"),
                  actions: [
                    FlatButton(
                      onPressed: (){
                        reponse?.data?.confirm = 1 ;
                        _makeFormPostRequest();
                      },
                      child: Text("Confirmer"),
                    ),
                    FlatButton(
                      onPressed: (){
                        _resetDataSend();
                      },
                      child: Text("Annuler"),
                    )
                  ],
                )
                    :Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Center(
                          child:
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical:  30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start ,
                              children: [
                                reponse?.title != null ?
                                //Affiche le title s'il n'est pas null
                                Html(data: "${reponse.title}",style: {
                                  "div": Style(
                                      fontSize: FontSize(12.0)
                                  ),
                                }): Container(),
                                reponse?.show?.qr_code_001 == true || start == true ?
                                //Affiche le champ qr_code_001 en auto focus, et écoute le changement de focus pour la validation du scan
                                TextFormField(
                                  focusNode: myFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Scanner le QR-Code du document papier',
                                  ),
                                  autofocus: true,
                                  controller: qrCode1Controller,


                                ) : Container(),
                                reponse?.show?.qr_code_001 == true ?
                                Html(data: "${reponse.data.qr_code_001}")
                                    : Container(),
                                reponse?.alert == null? Container() :
                                Visibility(
                                  visible: _visible,
                                  // Affiche l'alerte si elle n'est pas null, et la cache au bout de 3 secondes
                                  child: Html(data :"$alert",style: {
                                    "html": Style(color: Colors.red)
                                  }),
                                ),
                                reponse?.show?.qt == true?
                                Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: Text("QT / Unité de condi.",
                                      style: TextStyle(
                                        fontSize: 18,
                                      ),)
                                ) : Container(),
                                reponse?.show?.qt == true?
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Champ contenant la qt
                                    Flexible(
                                      child : TextFormField(
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'Veuillez rentrer la quantité';
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.numberWithOptions(signed: true,decimal: false),
                                        controller: qTController, // Only numbers can be entered// ,
                                      ),
                                    ),
                                    // Champ contenant la condi
                                    Flexible(
                                      child: DropdownButtonFormField<int>(
                                          value: condi,
                                          icon: Icon(Icons.arrow_downward),
                                          iconSize: 24,
                                          elevation: 16,
                                          onChanged: (int newValue) {
                                            setState(() {
                                              condi = newValue;
                                            });
                                          },
                                          items: [
                                            DropdownMenuItem(
                                              value:  3,
                                              child: Text("Carton"),
                                            ),
                                            DropdownMenuItem(
                                              value:  5,
                                              child: Text("Palette"),
                                            ),
                                            DropdownMenuItem(
                                              value:  2,
                                              child: Text("Boite"),
                                            )
                                          ]
                                      ),
                                    )
                                  ],
                                )
                                    : Container(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    reponse?.show?.dluo == true?
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Padding(
                                                padding: EdgeInsets.only(top: 5.0),
                                                child: Text("Date de DLUO",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),)
                                            ),
                                            // Champ DLUO, format date
                                            TextFormField(
                                              validator: (value) {
                                                if (value.isEmpty) {
                                                  return 'Veuillez rentrer la DLUO du produit';
                                                }
                                                return null;
                                              },
                                              decoration: const InputDecoration(
                                                hintText: 'dd-mm-yyyy',
                                              ),
                                              controller: dluoController,
                                              keyboardType: TextInputType.datetime,
                                            ),
                                          ],
                                        )
                                    ) : Flexible( child: Container(),),
                                    reponse?.show?.lot == true?
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Padding(
                                                padding: EdgeInsets.only(top: 5.0),
                                                child: Text("N° de LOT",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),)
                                            ),
                                            // Champ numero de lot
                                            TextFormField(
                                              validator: (value) {
                                                if (value.isEmpty) {
                                                  return 'Veuillez rentrer le numéro de lot du produit';
                                                }
                                                return null;
                                              },
                                              decoration: const InputDecoration(
                                                hintText: '123456789',
                                              ),
                                              controller: nLotController,
                                              keyboardType: TextInputType.visiblePassword,
                                            ),
                                          ],
                                        )
                                    ): Flexible( child: Container(),),

                                  ],
                                ),
                                // Champ zone
                                reponse?.show?.zone == true?
                                TextFormField(
                                  decoration: const InputDecoration(
                                    hintText: 'Zone',
                                  ),
                                  controller: zoneController,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Zone?';
                                    }
                                    return null;
                                  },
                                ) : Container(),
                                Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        // Affiche l'image si _path n'est pas null
                                        _path == null ? Container() :
                                        Image.file(File(_path))
                                        ,
                                        // Si _path est null et qu'une photo est demandée, bouton qui déclenche l'appareil photo -> take_picture.dart
                                        _path == null && reponse?.show?.photo == true?
                                        RaisedButton(
                                          color: Colors.deepPurpleAccent,
                                          onPressed: () {
                                            _showCamera();
                                          },
                                          child: Text('Prendre une photo',
                                            style: TextStyle(
                                                color: Colors.white
                                            ),
                                          ),
                                        ) : Container(),
                                        reponse?.show?.photo == true?
                                        // Champ pour le motif/Libelle de la photo
                                        TextFormField(
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            hintText: 'Motif',
                                          ),
                                          validator: (value) {
                                            if (value.isEmpty) {
                                              return 'Complétez le motif de la photo';
                                            }
                                            return null;
                                          },
                                          controller: motifController,
                                        ) : Container() ,
                                      ],)
                                ),
                                reponse?.show?.submit == true?
                                //Bouton submit pour les champs qui en ont besoin
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: RaisedButton(
                                    color: Colors.deepPurpleAccent,
                                    onPressed: () {
                                      _makeFormPostRequest();
                                    },
                                    child: Text('Envoyer',
                                      style: TextStyle(
                                          color: Colors.white
                                      ),
                                    ),
                                  ),
                                ) : Container()],
                            ),
                          ) ,
                        )
                      ],
                    )),
              ],
            )
        ));
  }


  Future _makeFormPostRequest() async {
    //Lance le chargement le temps que la requete soit faite
    setState(() {
      isLoading = true;
    });
    // Si DA_NULL est renvoyé dans qr_code_001 -> Annule la saisie et reset les valeurs
    if(reponse?.data?.qr_code_001 == "DA_NULL"){
      String time = DateTime.now().millisecondsSinceEpoch.toString();
      String key = "a895d407c10275cc190b01310dacdc0d";
      String content = "$key$time";
      String keypass = md5.convert(utf8.encode(content)).toString();


      print(time);
      print(keypass);

      // paramètres de la requete
      String urlEnvoi = 'https://cantalfret.proxipause.eu/qrcode.json';
      Map<String,String> headers = {
        'Content-type' : 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };


      var body ={"qr_code_001":"DA_NULL","qr_code_002":"$qrCode2Value","qr_code_003": "$qrCode3Value","qt":qTController.value.text,"condi":"$condi","dluo":"${dluoController.value.text}","lot":"${nLotController.value.text}","zone": "${zoneController.value.text}","confirm": "${reponse?.data?.confirm}","target":"analyse","keypass":"$keypass","keytime":"$time",};


      Response response = await post(urlEnvoi, headers: headers, body: body);
      print(body);

      // On récupère le json que l'on décode sous forme de map pour pouvoir l'afficher
      if(response.body.isNotEmpty && response.statusCode == 200) {
        Map map = jsonDecode(response.body);
        setState(() {
          reponse = Reponse.fromJson(map);
          print(response.statusCode);
          print(response.body);
          qrCode2Value = reponse?.data?.qr_code_002;
          qrCode3Value = reponse?.data?.qr_code_003;
          start = false;
          if (reponse?.show?.print == true){
            _print();
            _resetOnPost();
            setState(() {
              qrCode1Value = "";
            });
          }
          if(reponse?.alert == "Code inconnu"){
            _resetOnPost();
            setState(() {
              qrCode1Value = "";
            });
          }
          if(reponse?.alert == false){
            alert = "";
            _resetOnPost();
            setState(() {
              qrCode1Value = "";
            });
          }
          else {
            alert = reponse?.alert;
          }
          setState(() {
            isLoading =false;
            _visible = true;
          });
          _toggle();
        });
      }
    }else{
      // Si on envoie une photo, rajoute les champs photo et libelle a la requete

      if(reponse?.show?.photo == true){
        // Assigne la valeur du champ qrcode1 à qrcode 1 s'il est null ou vide
        if(qrCode1Value == null || qrCode1Value == ""){
          qrCode1Value = qrCode1Controller.value.text;
        }
        setState(() {
          isLoading = true;
        });
        // Encodage de l'image prise par l'appareil photo avant envoi en base64
        File imageFile = File(_path);
        print(_path);
        List<int> imageBytes = imageFile.readAsBytesSync();
        String reserve = base64Encode(imageBytes);

        print(reserve);
        // Calcul de la clé et convert en md5
        String time = DateTime.now().millisecondsSinceEpoch.toString();
        String key = "a895d407c10275cc190b01310dacdc0d";
        String content = "$key$time";
        String keypass = md5.convert(utf8.encode(content)).toString();


        print(time);
        print(keypass);

        // paramètres de la requete
        String urlEnvoi = 'https://cantalfret.proxipause.eu/qrcode.json';
        Map<String,String> headers = {
          'Content-type' : 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        };
        var body = {
          "qr_code_001": "$qrCode1Value",
          "qr_code_002": "$qrCode2Value",
          "qr_code_003": "$qrCode3Value",
          "qt": qTController.value.text,
          "condi": "$condi",
          "dluo": "${dluoController.value.text}",
          "lot": "${nLotController.value.text}",
          "zone": "${zoneController.value.text}",
          "libelle_reserve": "${motifController.value.text}",
          "confirm": "${reponse?.data?.confirm}",
          "target": "analyse",
          "keypass": "$keypass",
          "keytime" : "$time",
          "base64" : reserve,
        };


        Response response = await post(urlEnvoi, headers: headers, body: body);
        print(body);

        // Si l'envoi a été fait, On récupère le json que l'on décode sous forme de map pour pouvoir l'afficher
        if(response.body.isNotEmpty && response.statusCode == 200) {
          Map map = jsonDecode(response.body);
          setState(() {
            reponse = Reponse.fromJson(map);
            print(response.statusCode);
            print(response.body);
            // on stocke la réponse qrcode002 dans une variable pour la garder en mémoire et pouvoir la renvoyer
            qrCode2Value = reponse?.data?.qr_code_002;
            qrCode3Value = reponse?.data?.qr_code_003;

            if (reponse?.show?.print == true){
              // si l'impression est demandée, imprime, et reset les valeurs
              _print();
              _resetOnPost();
              setState(() {
                qrCode1Value = "";
              });
            }
            if(reponse?.alert == "Code inconnu"){
              // si l'alerte est Code inconnu, reset les valeurs
              _resetOnPost();
              setState(() {
                qrCode1Value = "";
              });
            }
            if(reponse?.alert == false){
              // Si l'alert == false, retourne une string vide a la place (gere les erreurs d'affichage de flutter)
              alert = "";
            }
            else {
              // sinon, renvoie l'alert reçue dans son controller pour l'afficher
              alert = reponse?.alert;
            }
            // arrete le chargement, affiche l'alert pendant 3 secondes puis le cache, reset les valeurs
            setState(() {
              reserve = "";
              _visible = true;
              isLoading = false;
            });
            _resetDataSend();
            _toggle();
          });
        }

      }else{
        if(qrCode1Value == null || qrCode1Value == "" || reponse?.alert == "Scanner la palette de stockage" || reponse?.alert == "Appel des produits "){
          qrCode1Value = qrCode1Controller.value.text;
        }
        setState(() {
          isLoading = true;
        });
        // Si on n'envoie pas de photo
        // Calcul de la clé et convert en md5
        String time = DateTime.now().millisecondsSinceEpoch.toString();
        String key = "a895d407c10275cc190b01310dacdc0d";
        String content = "$key$time";
        String keypass = md5.convert(utf8.encode(content)).toString();


        print(time);
        print(keypass);

        // paramètres de la requete
        String urlEnvoi = 'https://cantalfret.proxipause.eu/qrcode.json';
        Map<String,String> headers = {
          'Content-type' : 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        };


        var body ={"qr_code_001":"$qrCode1Value","qr_code_002":"$qrCode2Value","qr_code_003": "$qrCode3Value","qt":qTController.value.text,"condi":"$condi","dluo":"${dluoController.value.text}","lot":"${nLotController.value.text}","zone": "${zoneController.value.text}","confirm": "${reponse?.data?.confirm}","target":"analyse","keypass":"$keypass","keytime":"$time",};


        Response response = await post(urlEnvoi, headers: headers, body: body);
        print(body);

        // Si l'envoi a été fait, On récupère le json que l'on décode sous forme de map pour pouvoir l'afficher
        if(response.body.isNotEmpty && response.statusCode == 200) {
          Map map = jsonDecode(response.body);
          setState(() {
            reponse = Reponse.fromJson(map);
            print(response.statusCode);
            print(response.body);
            print(reponse.data);
            // on stocke la réponse qrcode002 dans une variable pour la garder en mémoire et pouvoir la renvoyer
            qrCode2Value = reponse?.data?.qr_code_002;
            qrCode3Value = reponse?.data?.qr_code_003;
            title = """${reponse.title}""";
            start = false;
            if(reponse?.title == ""){
              _resetOnPost();
              setState(() {
                qrCode1Value = "";
              });
            }
            if(reponse?.alert == "Code inconnu"){
              // si l'alerte est Code inconnu, reset les valeurs
              _resetOnPost();
              setState(() {
                qrCode1Value = "";
              });
            }
            if (reponse?.show?.print == true){
              // si l'impression est demandée, imprime, et reset les valeurs
              _print();
              _resetOnPost();
              setState(() {
                qrCode1Value = "";
              });
            }
            // Si l'alert == false, retourne une string vide a la place (gere les erreurs d'affichage de flutter)
            if(reponse?.alert == false){
              alert = "";
            }
            else {
              // sinon, renvoie l'alert reçue dans son controller pour l'afficher
              alert = reponse?.alert;
            }
            // arrete le chargement, affiche l'alert pendant 3 secondes puis le cache, reset les valeurs
            setState(() {
              _visible = true;
              isLoading = false;
                qrCode1Value = "";
            });
            _toggle();
          });
        }
      }
    }

  }
}


