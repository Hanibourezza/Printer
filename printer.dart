// ignore_for_file: prefer_const_constructors

import 'package:audioplayers/audioplayers.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salepoint/Auxwidget/defaultbutton.dart';
import 'package:salepoint/configuration/constant.dart';

import '../main.dart';
import '../modele/bon.dart';
import '../modele/bondetails.dart';
import '../modele/cartmodele.dart';
import '../modele/client.dart';
import '../modele/itemscartmodel.dart';
import '../modele/product.dart';

class Printer extends StatefulWidget {
  final bool now;
  final String balance;
  // ignore: non_constant_identifier_names
  final int id_client;
  final bool checked;
  final String? nameclient;
  final String? heure;
  final String? date;
  final double? totalprice;
  final int? id_bon;

  // ignore: prefer_const_constructors_in_immutables
  Printer(
      {Key? key,
      required this.balance,
      required this.id_client,
      required this.checked,
      this.nameclient,
      required this.now,
      this.heure,
      this.date,
      this.totalprice,
      this.id_bon})
      : super(key: key);

  @override
  _PrinterState createState() => _PrinterState();
}

class _PrinterState extends State<Printer> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  String tips = 'no service connected';
  bool _connected = false;
  late List<BluetoothDevice> _devices = [];
  // ignore: prefer_final_fields
  late List<BluetoothDevice> _selectedPrinter = [];
  @override
  void initState() {
    super.initState();

    bluetoothPrint.scanResults.listen((devices) async {
      setState(() {
        _devices = devices;
      });
    });
    _startScanDevices();
  }

  void _startScanDevices() async {
    setState(() {
      _devices = [];
    });
    // ignore: prefer_const_constructors
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));
    bool? isConnected = await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected != null && isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<BluetoothDevice>>(
        stream: bluetoothPrint.scanResults,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          // ignore: prefer_const_constructors
                          icon: Icon(
                            Icons.arrow_back,
                            size: 19,
                          )),
                      Text(
                        'Imprimant Setings',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "data",
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                  Expanded(
                      flex: 9,
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: 50.0,
                            child: InkWell(
                              onTap: () => _openDialog(context),
                              // ignore: prefer_is_empty
                              child: Text(_devices.length == 0
                                  ? '*** No devices were found ***'
                                  : 'Was found ${_devices.length} devices.'),
                            ),
                          ),
                          SizedBox(
                            width: 300,
                            child: Defaultbutton(
                              important: false,
                              txt: "Selectionner une imprimant'",
                              press: () => _openDialog(context),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                  // ignore: prefer_is_empty
                                  _selectedPrinter.length > 0
                                      ? _selectedPrinter[0].name.toString()
                                      : 'No printer selected',
                                  style: TextStyle(fontSize: 18.0)),
                            ),
                          ),
                        ],
                      )),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 200,
                        child: Consumer<Cartmodele>(
                            builder: ((context, cartmodele, child) {
                          return Defaultbutton(
                            important: true,
                            press: () async {
                              // ignore: avoid_print
                              print(_connected);
                              if (_connected == true) {
                                if (widget.now == true) {
                                  print("oui");
                                  final now = new DateTime.now();
                                  String formatter =
                                      DateFormat('yMd').format(now);
                                  String formattedTime =
                                      DateFormat('kk:mm:a').format(now);

                                  setState(() {
                                    DatabaseHelperBon.instance.add(Bon(
                                        benficetotal: cartmodele.totalbenfice,
                                        heure: formattedTime,
                                        id_client: widget.id_client,
                                        date: formatter,
                                        totalprice: cartmodele.totalprice,
                                        balance: widget.checked == true
                                            ? double.parse(widget.balance)
                                            : cartmodele.totalprice,
                                        type: 0)); //balance must be in enter
                                  });
                                  var bonid;
                                  await DatabaseHelperBon.instance
                                      .getLast()
                                      .then((value) {
                                    bonid = value.id;
                                  });

                                  for (int i = 0;
                                      i < cartmodele.listproductitem.length;
                                      i++) {
                                    var gtqte;
                                    await DatabaseHelper.instance
                                        .getProductbyid(cartmodele
                                            .listproductitem[i].product.id!)
                                        .then((value) {
                                      gtqte = value.qte;
                                    });
                                    setState(() {
                                      DatabaseHelper.instance.update(Product(
                                          id: cartmodele
                                              .listproductitem[i].product.id!,
                                          cat: cartmodele
                                              .listproductitem[i].product.cat,
                                          deleted: cartmodele.listproductitem[i]
                                              .product.deleted,
                                          image: cartmodele
                                              .listproductitem[i].product.image,
                                          name: cartmodele
                                              .listproductitem[i].product.name,
                                          price: cartmodele
                                              .listproductitem[i].product.price,
                                          priceV: cartmodele.listproductitem[i]
                                              .product.priceV,
                                          qte: gtqte -
                                              cartmodele.listproductitem[i]
                                                  .numofproduct));
                                    });
                                    DatabaseHelperbondetails.instance.add(
                                        Bondetails(
                                            benfice: cartmodele
                                                    .listproductitem[i]
                                                    .product
                                                    .priceV -
                                                cartmodele.listproductitem[i]
                                                    .product.price,
                                            qteback: 0,
                                            id_bondetails: bonid,
                                            id_product: cartmodele
                                                .listproductitem[i].product.id!,
                                            price: cartmodele.listproductitem[i]
                                                .product.priceV,
                                            qte: cartmodele.listproductitem[i]
                                                .numofproduct));
                                  }
                                  var nameclient;
                                  await DatabaseHelperClient.instance
                                      .getclientbyid(widget.id_client)
                                      .then((value) {
                                    nameclient = value.nom_prenom;
                                  });
                                  _printTest(
                                      nameclient,
                                      cartmodele.listproductitem,
                                      formattedTime,
                                      formatter,
                                      cartmodele.totalprice);

                                  cartmodele.removeall();

                                  Navigator.pushNamed(
                                      context, Mainpage.routeName);
                                  final player = new AudioCache();
                                  String alarmAudioPath = "tst.wav";

                                  player.play(alarmAudioPath, volume: 50);

                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                            Radius.circular(20),
                                          )),
                                          title: null,
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 100,
                                                width: 100,
                                                child: SvgPicture.asset(
                                                  "img/finish.svg",
                                                  color: kPrimarycolor,
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text.rich(
                                                        TextSpan(children: [
                                                      TextSpan(
                                                          text:
                                                              "L'operation est faite avec succeés",
                                                          style:
                                                              GoogleFonts.lato(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 22))
                                                    ])),
                                                  )
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text.rich(TextSpan(children: [
                                                    TextSpan(
                                                        text:
                                                            "Cette perte est enregestreés \n dans l'historique",
                                                        style: GoogleFonts.lato(
                                                            fontSize: 9))
                                                  ]))
                                                ],
                                              )
                                            ],
                                          ));
                                    },
                                  );
                                } else {
                                  List<Itemcartmodel> listprint = [];
                                  List<Bondetails> listbondetails = [];

                                  await DatabaseHelperbondetails.instance
                                      .getBondetailsbyid(widget.id_bon!)
                                      .then((value) {
                                    setState(() {
                                      listbondetails = value;
                                    });
                                  });
                                  for (var i = 0;
                                      i < listbondetails.length;
                                      i++) {
                                    var id;
                                    var qte;
                                    var qteback;
                                    var cat;
                                    var deleted;
                                    var image;
                                    var name;
                                    var price;
                                    var priceV;

                                    await DatabaseHelper.instance
                                        .getProductbyid(
                                            listbondetails[i].id_product)
                                        .then((value) {
                                      id = value.id;
                                      qte = 0;
                                      cat = value.cat;
                                      deleted = value.deleted;
                                      image = value.image;
                                      name = value.name;
                                      price = listbondetails[i].price;
                                    });
                                    listprint.add(Itemcartmodel(
                                        product: Product(
                                            id: id,
                                            qte: qte,
                                            cat: cat,
                                            deleted: deleted,
                                            image: image,
                                            name: name,
                                            price: price,
                                            priceV: priceV),
                                        numofproduct: listbondetails[i].qte -
                                            listbondetails[i].qteback));
                                  }
                                  var totalpricebon;
                                  await DatabaseHelperBon.instance
                                      .getBonbyid(widget.id_bon!)
                                      .then(
                                    (value) {
                                      totalpricebon = value.totalprice;
                                    },
                                  );
                                  _printTest(
                                      widget.nameclient!,
                                      listprint,
                                      widget.heure!,
                                      widget.date!,
                                      totalpricebon!);
                                }
                              } else {
                                _printSnackBar(context,
                                    'YOU MUST SELECT A PRINTING DEVICE');
                              }
                            },
                            txt: 'Imprimer',
                          );
                        }))),
                  )),
                ],
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: StreamBuilder(
        stream: bluetoothPrint.isScanning,
        initialData: false,
        builder: (_, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return FloatingActionButton(
              onPressed: () => bluetoothPrint.stopScan(),
              child: Icon(Icons.stop),
              backgroundColor: Colors.redAccent,
            );
          } else {
            return FloatingActionButton(
              backgroundColor: kPrimarycolor,
              onPressed: () => _startScanDevices(),
              child: Icon(Icons.search),
            );
          }
        },
      ),
    );
  }

  Future _openDialog(BuildContext _context) {
    return showDialog(
        context: _context,
        builder: (_) => CupertinoAlertDialog(
              title: Column(
                // ignore: prefer_const_literals_to_create_immutables
                children: [
                  Text("Select the printer device to connect"),
                  // ignore: prefer_const_constructors
                  SizedBox(
                    height: 15.0,
                  ),
                ],
              ),
              content: _setupDialogContainer(_context),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(_context).pop();
                    },
                    child: Text('Close'))
              ],
            ));
  }

  Widget _setupDialogContainer(BuildContext _context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200.0,
          width: 300.0,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: _devices.length,
              itemBuilder: (BuildContext _context, int index) {
                return GestureDetector(
                  onTap: () async {
                    await bluetoothPrint.connect(_devices[index]);
                    setState(() {
                      _selectedPrinter.add(_devices[index]);
                    });
                    Navigator.of(_context).pop();
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 70.0,
                        padding: EdgeInsets.only(left: 10.0),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(
                              width: 10.0,
                            ),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_devices[index].name ?? ''),
                                Text(_devices[index].address.toString()),
                                Flexible(
                                    child: Text(
                                  'Click to select the printer',
                                  style: TextStyle(color: Colors.grey[700]),
                                  textAlign: TextAlign.justify,
                                )),
                              ],
                            )),
                          ],
                        ),
                      ),
                      Divider(),
                    ],
                  ),
                );
              }),
        )
      ],
    );
  }

  _printSnackBar(BuildContext _context, String _text) {
    final snackBar = SnackBar(
      content: Text(_text),
      action: SnackBarAction(label: 'Close', onPressed: () {}),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _printTest(String clientname, List<Itemcartmodel> lisprint, String date,
      String heure, double totalprice) async {
    Map<String, dynamic> config = Map();
    List<LineText> list = [];

    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Livarison app',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: date,
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: heure,
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: clientname,
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Cash ',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    for (var i = 0; i < lisprint.length; i++) {
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: lisprint[i].product.name,
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: lisprint[i].numofproduct.toString(),
          weight: 1,
          align: LineText.ALIGN_RIGHT,
          linefeed: 1));
    }
    list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: totalprice.toString(),
        weight: 1,
        align: LineText.ALIGN_LEFT,
        linefeed: 1));
    await bluetoothPrint.printReceipt(config, list);
  }
}
