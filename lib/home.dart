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
import 'package:serial_number/serial_number.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_esc_printer/flutter_esc_printer.dart';


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _serialNumber = 'Unknown';
  SocketIO socket;
  bool isLoading = false;
  OtaEvent currentEvent;
  String _path = null;
  String alert;
  String addalert ="";
  String result = "";
  Reponse reponse;
  bool connected;
  bool start;
  var title;
  bool _visible = true;
  String qrCode1Value;
  String qrCode2Value;
  String qrCode3Value;
  FocusNode _focusNodedluo;
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
    reponse?.data?.condi = "";
    reponse?.data?.zone = "";
    reponse?.data?.qt = 0;
    reponse?.data?.dluo = "";
    reponse?.data?.url_pdf = "";
    if (reponse?.data?.condi == 2 || reponse?.data?.condi == 3 || reponse?.data?.condi == 5){
      setState(() {
        condi = reponse?.data?.condi;
      });
    }
    isConnected();
    _resetOnPost();
    super.initState();
    initPlatformState();
    _focusNodedluo =FocusNode();
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

  _launchURL() async {
    const url = 'http://www.archeonavale.org/pdf/cordeliere/test.pdf';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Impression Bluetooth
  _blueprint() async {
    List<String> printList = reponse?.data?.zebra?.zpl;

    for (var l in printList) {
      const PaperSize paper = PaperSize.mm80;
      PrinterBluetoothManager _printerBluetoothManager = PrinterBluetoothManager();
      _printerBluetoothManager.selectPrinter("${reponse?.data?.zebra?.ipPrint}");
      final Ticket ticket = Ticket(paper);

      ticket.text(l);

      final res = await _printerBluetoothManager.printTicket(ticket);
      await Future.delayed(Duration(seconds: 3));
    }
  }
// Met a jour l'application, necessite de mettre a jour le fichier app-release.apk
  // pour cela créer un build de l'apk dans Build -> Flutter -> Build APK
  // l'apk se trouve dans le dossier de l'application Dossier\build\app\outputs\flutter-apk
  // /!\ bien prendre le fichier app-release.apk
  Future<void> tryOtaUpdate() async {
    try {

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

  // Permet de vérifier si le PDA est connecté à internet et affiche un message si non connecté a internet
  void isConnected() async{
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          connected = true;
          print("connecté a internet");
        });
      }
    } on SocketException catch (_) {
      setState(() {
        connected = false;
        print("non connecté");
      });
    }
  }

  void _reset() {
    _resetOnPost();
    _resetDataSend();
    setState(() {
      qTController = TextEditingController(text: "");
      qrCode1Value ="";
      qrCode2Value="";
      qrCode3Value ="";
      addalert = "";
      alert = "";
    });
  }
  // Reset les valeurs des champs Textfield(valeurs envoyées)
  void _resetOnPost() async {

    setState(() {
      qrCode1Controller = TextEditingController(text: "");
      dluoController = TextEditingController(text: "");
      nLotController = TextEditingController(text: "");
      zoneController = TextEditingController(text: "");
      motifController = TextEditingController(text: "");
      _path = null;
      isLoading = false;
    });
  }
  // Remise à zéro des valeurs reçues (icone maison)
  void _resetDataSend() async {
    setState(() {
      isLoading = false;
      reponse?.title = "";
      reponse?.alert = "";
      reponse?.data?.qr_code_001 = "";
      reponse?.data?.qr_code_002 = "";
      reponse?.data?.qr_code_003 = "";
      reponse?.data?.confirm = 0;
      reponse?.data?.condi = "";
      reponse?.data?.zone = "";
      reponse?.data?.dluo = "";
      reponse?.data?.url_pdf = "";
      reponse?.show?.qr_code_001 = true;
      reponse?.show?.confirm = false;
      reponse?.show?.dluo = false;
      reponse?.show?.zone = false;
      reponse?.show?.reserve = false;
      start = true;
      reponse?.show?.qt = false;
      reponse?.show?.print = false;
      reponse?.show?.submit = false;
      reponse?.show?.lot = false;
      qrCode1Value = "";
      _path = null;
    });
  }


// Cache le champ alerte au bout de 10 secondes
  _toggle() async {
    await new Future.delayed(const Duration(seconds : 10));
    setState(() {
      _visible = !_visible;
    });
    return _visible;
  }

  // lance l'impression d'une étiquette en pdf
  Future _print() async{
    // récupère la liste des étiquettes à imprimer
    List<String> printList = reponse?.data?.zebra?.zpl;
    // parcours le tableau pour envoyer une socket par étiquette
    for (var l in printList) {
      // connexion à la socket via l'adresse ip de l'imprimante envoyée par l'API (192.168.1.76) et du port (9100)
      Socket socket = await Socket.connect(reponse?.data?.zebra?.ipPrint, 9100);
      print('connected');
      // écoute la socket
      socket.listen((List<int> event) {
        print(utf8.decode(event));
      });

      // envoie les data en zpl
      socket.add(utf8.encode(l));
      // attend 3 secondes
      await Future.delayed(Duration(seconds: 3));

      // .. ferme la socket
      socket.close();
    }

  }

  Future<void> initPlatformState() async {
    String serialNumber;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      serialNumber = await SerialNumber.serialNumber;
    } on PlatformException {
      serialNumber = 'Failed to get serial number.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _serialNumber = serialNumber;
    });
    print(_serialNumber);
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
    Future.delayed(const Duration(), () => SystemChannels.textInput.invokeMethod('TextInput.hide'));
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          //Bouton qui reset les valeurs envoyées et reçues
            leading: IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Redémarrer',
              onPressed: () {
                _reset();
              },
            ),),
        endDrawer: Drawer(
          child:
          ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                  child:
                  Text('Menu',style: TextStyle(color: Colors.white),),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent
              ),
              ),
              ListTile(
                leading: Icon(Icons.content_paste),
                title: Text('Inventaire'),
                onTap: (){
                  _launchURL();
                },
              ),
              ListTile(
                leading: Icon(Icons.content_paste),
                title: Text('Test'),
                onTap: (){
                  _blueprint();
                },
              ),
              ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Mise à jour'),
                onTap: (){
                  tryOtaUpdate();
                },
              )
            ],
          ),
        ),
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
                            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical:  10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start ,
                              children: [
                                Visibility(
                                  visible: _visible,
                                  child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          addalert = "";
                                        });
                                      },
                                      child: Row(children: [
                                        Text("$addalert",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 17.0
                                          )
                                          ,),
                                        Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical:  0),
                                            child:
                                            addalert != "" ?
                                            Icon(Icons.cancel_outlined,color: Colors.red,): Text("")
                                            )

                                      ],)
                                  ),
                                )
                                ,
                                reponse?.title != null ?
                                //Affiche le title s'il n'est pas null
                                Html(data: "${reponse.title}",style: {
                                  "u": Style(
                                  fontSize: FontSize(19.0)),
                                  "div": Style(
                                      fontSize: FontSize(19.0)
                                  ),
                                }): Container(),
                                reponse?.show?.qr_code_001 == true || start == true ?
                                //Affiche le champ qr_code_001 en auto focus, et écoute le changement de focus pour la validation du scan
                                TextFormField(
                                  focusNode: myFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Scanner le QR-Code',
                                  ),
                                  autofocus: true,
                                  controller: qrCode1Controller,


                                ) : Container(),
                                reponse?.alert == null? Container() :
                                Visibility(
                                  visible: _visible,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _visible = false;
                                      });
                                      },
                                      child:
                                          Row(
                                            children: [
                                              Expanded(
                                                  child:
                                                  Html(
                                                      data :"$alert",
                                                      style: {
                                                        "html": Style(
                                                            color: Colors.red,
                                                            fontSize: FontSize(18.0)
                                                        )
                                                      })
                                              ),
                                              alert != ""?
                                              Icon(Icons.cancel_outlined,color: Colors.red) : Text(""),
                                            ],
                                          )
                                        ),
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
                                        controller: qTController,
                                          textInputAction: TextInputAction.next,
                                          onEditingComplete: () => FocusScope.of(context).nextFocus()// Only numbers can be entered// ,
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
                                              focusNode: _focusNodedluo,
                                              controller: dluoController,
                                              keyboardType: TextInputType.datetime,
                                              textInputAction: TextInputAction.next,
                                              onEditingComplete: () => FocusScope.of(context).nextFocus(),
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp("[0-9-]")),
                                                LengthLimitingTextInputFormatter(10),
                                                _DateFormatter(),
                                              ],
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
                                                textInputAction: TextInputAction.next,
                                                onEditingComplete: () => FocusScope.of(context).nextFocus()
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
                                        _path == null && reponse?.show?.reserve == true?
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
                                        reponse?.show?.reserve == true?
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
    isConnected();
    if(connected == false){
      _resetDataSend();
      _resetOnPost();
      setState(() {
        isLoading = false;
      });
    }
    else{
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


        var body ={
          "qr_code_001":"DA_NULL",
          "qr_code_002":"$qrCode2Value",
          "qr_code_003": "$qrCode3Value",
          "qt":qTController.value.text,
          "condi":"$condi",
          "dluo":"${dluoController.value.text}",
          "lot":"${nLotController.value.text}",
          "zone": "${zoneController.value.text}",
          "confirm": "${reponse?.data?.confirm}",
          "target":"analyse",
          "keypass":"$keypass",
          "keytime":"$time",
          "nPDA":"$_serialNumber"
        };


        Response response = await post(urlEnvoi, headers: headers, body: body);
        print(body);

        // On récupère le json que l'on décode sous forme de map pour pouvoir l'afficher
        if(response.body.isNotEmpty && response.statusCode == 200) {
          Timer timer = new Timer(new Duration(seconds: 5), () {
            setState(() {
              isLoading = false;
              addalert = "Temps d'attente trop long";
            });
          });
          Map map = jsonDecode(response.body);
          setState(() {
            reponse = Reponse.fromJson(map);
            print(response.statusCode);
            print(response.body);
            if(reponse?.data?.condi != null){
              if(reponse?.data?.condi == "3"){
                setState(() {
                  condi = 3;
                });
              }
              if(reponse?.data?.condi == "2"){
                setState(() {
                  condi = 2;
                });
              }
              if(reponse?.data?.condi == "5"){
                setState(() {
                  condi = 5;
                });
              }
            }
            qrCode2Value = reponse?.data?.qr_code_002;
            qrCode3Value = reponse?.data?.qr_code_003;
            start = false;
            if (reponse?.show?.print == true){
              _blueprint();
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
              timer.cancel();
            }
            setState(() {
              isLoading =false;
              timer.cancel();
              _visible = true;
            });
            _resetOnPost();
            timer.cancel();
          });
        }
      }else{
        // Si on envoie une photo, rajoute les champs photo et libelle a la requete

        if(reponse?.show?.reserve == true){
          // Assigne la valeur du champ qrcode1 à qrcode 1 s'il est null ou vide
          if(qrCode1Value == null || qrCode1Value == ""|| reponse?.alert == "Scanner la palette de stockage" || reponse?.alert == "Appel des produits "){
            qrCode1Value = qrCode1Controller.value.text;
          }
          Timer timer = new Timer(new Duration(seconds: 5), () {
            setState(() {
              isLoading = false;
              addalert = "Temps d'attente trop long";
            });
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
            "nPDA":"$_serialNumber",
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
              if(reponse?.data?.condi != null){
                if(reponse?.data?.condi == "3"){
                  setState(() {
                    condi = 3;
                  });
                }
                if(reponse?.data?.condi == "2"){
                  setState(() {
                    condi = 2;
                  });
                }
                if(reponse?.data?.condi == "5"){
                  setState(() {
                    condi = 5;
                  });
                }
              }
              qrCode2Value = reponse?.data?.qr_code_002;
              qrCode3Value = reponse?.data?.qr_code_003;

              if (reponse?.show?.print == true){
                // si l'impression est demandée, imprime, et reset les valeurs
                _blueprint();
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
              if(reponse?.show?.reserve == false){
                setState(() {
                  reserve ="";
                  _path =null;
                  isLoading =false;
                  timer.cancel();
                });
              }
              if(reponse?.alert == false){
                // Si l'alert == false, retourne une string vide a la place (gere les erreurs d'affichage de flutter)
                alert = "";
                timer.cancel();
              }
              else {
                // sinon, renvoie l'alert reçue dans son controller pour l'afficher
                alert = reponse?.alert;
                timer.cancel();
              }
              // arrete le chargement, affiche l'alert pendant 3 secondes puis le cache, reset les valeurs
              setState(() {
                reserve = "";
                reponse?.data?.condi != null ? condi = reponse?.data?.condi : condi = 3;
                qrCode1Value = reponse?.data?.qr_code_001;
                if(reponse?.data?.qt == 0){
                  qTController = TextEditingController(text: "");
                }
                _visible = true;
                isLoading = false;
                timer.cancel();
              });
              _resetOnPost();
              timer.cancel();
            });
          }

        }else{
          if(qrCode1Value == null || qrCode1Value == "" || reponse?.alert == "Scanner la palette de stockage" || reponse?.alert == "Appel des produits "){
            qrCode1Value = qrCode1Controller.value.text;
          }
          Timer timer = new Timer(new Duration(seconds: 5), () {
            setState(() {
              isLoading = false;
              addalert = "Temps d'attente trop long";
            });
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


          var body ={"qr_code_001":"$qrCode1Value",
            "qr_code_002":"$qrCode2Value",
            "qr_code_003": "$qrCode3Value",
            "qt":qTController.value.text,
            "condi":"$condi",
            "dluo":"${dluoController.value.text}",
            "lot":"${nLotController.value.text}",
            "zone": "${zoneController.value.text}",
            "confirm": "${reponse?.data?.confirm}",
            "target":"analyse",
            "keypass":"$keypass",
            "keytime":"$time",
            "nPDA":"$_serialNumber"
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
              print(reponse.data);
              if(reponse?.data?.condi != null){
                if(reponse?.data?.condi == "3"){
                  setState(() {
                    condi = 3;
                  });
                }
                if(reponse?.data?.condi == "2"){
                  setState(() {
                    condi = 2;
                  });
                }
                if(reponse?.data?.condi == "5"){
                  setState(() {
                    condi = 5;
                  });
                }
              }
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
                  timer.cancel();
                });
              }
              if (reponse?.show?.print == true){
                // si l'impression est demandée, imprime, et reset les valeurs
                _blueprint();
                _resetOnPost();
                setState(() {
                  qrCode1Value = "";
                  timer.cancel();
                });
              }
              // Si l'alert == false, retourne une string vide a la place (gere les erreurs d'affichage de flutter)
              if(reponse?.alert == false){
                alert = "";
                _resetOnPost();
                timer.cancel();
              }
              else {
                // sinon, renvoie l'alert reçue dans son controller pour l'afficher
                alert = reponse?.alert;
                _resetOnPost();
                timer.cancel();
              }
              // arrete le chargement, affiche l'alert pendant 3 secondes puis le cache, reset les valeurs
              setState(() {
                if(reponse?.data?.qt == 0){
                  qTController = TextEditingController(text: "");
                }
                _visible = true;
                isLoading = false;
                timer.cancel();
                if(reponse?.data?.condi != null){
                  if(reponse?.data?.condi == "3"){
                    setState(() {
                      condi = 3;
                    });
                  }
                  if(reponse?.data?.condi == "2"){
                    setState(() {
                      condi = 2;
                    });
                  }
                  if(reponse?.data?.condi == "5"){
                    setState(() {
                      condi = 5;
                    });
                  }
                }
                qrCode1Value = reponse?.data?.qr_code_001;
              });
              timer.cancel();
              _resetOnPost();
            });
          }
        }
      }
    }
    }
  }

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue prevText, TextEditingValue currText) {
    int selectionIndex;

    // Get the previous and current input strings
    String pText = prevText.text;
    String cText = currText.text;
    // Abbreviate lengths
    int cLen = cText.length;
    int pLen = pText.length;

    if (cLen == 1) {
      // Can only be 0, 1, 2 or 3
      if (int.parse(cText) > 3) {
        // Remove char
        cText = '';
      }
    } else if (cLen == 2 && pLen == 1) {
      // Days cannot be greater than 31
      int dd = int.parse(cText.substring(0, 2));
      if (dd == 0 || dd > 31) {
        // Remove char
        cText = cText.substring(0, 1);
      } else {
        // Add a - char
        cText += '-';
      }
    } else if (cLen == 4) {
      // Can only be 0 or 1
      if (int.parse(cText.substring(3, 4)) > 1) {
        // Remove char
        cText = cText.substring(0, 3);
      }
    } else if (cLen == 5 && pLen == 4) {
      // Month cannot be greater than 12
      int mm = int.parse(cText.substring(3, 5));
      if (mm == 0 || mm > 12) {
        // Remove char
        cText = cText.substring(0, 4);
      } else {
        // Add a - char
        cText += '-';
      }
    } else if ((cLen == 3 && pLen == 4) || (cLen == 6 && pLen == 7)) {
      // Remove - char
      cText = cText.substring(0, cText.length - 1);
    } else if (cLen == 3 && pLen == 2) {
      if (int.parse(cText.substring(2, 3)) > 1) {
        // Replace char
        cText = cText.substring(0, 2) + '-';
      } else {
        // Insert - char
        cText =
            cText.substring(0, pLen) + '-' + cText.substring(pLen, pLen + 1);
      }
    } else if (cLen == 6 && pLen == 5) {
      // Can only be 1 or 2 - if so insert a - char
      int y1 = int.parse(cText.substring(5, 6));
      if (y1 < 1 || y1 > 2) {
        // Replace char
        cText = cText.substring(0, 5) + '-';
      } else {
        // Insert - char
        cText = cText.substring(0, 5) + '-' + cText.substring(5, 6);
      }
    } else if (cLen == 7) {
      // Can only be 1 or 2
      int y1 = int.parse(cText.substring(6, 7));
      if (y1 < 1 || y1 > 2) {
        // Remove char
        cText = cText.substring(0, 6);
      }
    } else if (cLen == 8) {
      // Can only be 19 or 20
      int y2 = int.parse(cText.substring(6, 8));
      if (y2 < 19 || y2 > 20) {
        // Remove char
        cText = cText.substring(0, 7);
      }
    }

    selectionIndex = cText.length;
    return TextEditingValue(
      text: cText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
