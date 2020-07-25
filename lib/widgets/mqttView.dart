import 'dart:io' show Platform;
import 'package:device_id/device_id.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mqtt_app/mqtt/state/MQTTAppState.dart';
import 'package:flutter_mqtt_app/mqtt/MQTTManager.dart';

class MQTTView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTViewState();
  }
}

class _MQTTViewState extends State<MQTTView> {
  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  MQTTAppState currentAppState;
  MQTTManager manager;
  // String _deviceid = 'Unknown';
  String deviceid = '';
  String nikname = '';
  @override
  void initState() {
    super.initState();
    initDeviceId();

    _hostTextController.text = 'test.mosquitto.org';
    _topicTextController.text = 'flutter/amp/cool';
  }

  @override
  void dispose() {
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    _nameTextController.dispose();
    super.dispose();
  }

  Future<void> initDeviceId() async {
    // String imei;
    // String meid;

    deviceid = await DeviceId.getID;
    // try {
    //   imei = await DeviceId.getIMEI;
    //   meid = await DeviceId.getMEID;
    // } on PlatformException catch (e) {
    //   print(e.message);
    // }

    if (!mounted) return;

    setState(() {
      deviceid = deviceid;
    });
  }

  /*
  _printLatestValue() {
    print("Second text field: ${_hostTextController.text}");
    print("Second text field: ${_messageTextController.text}");
    print("Second text field: ${_topicTextController.text}");
  }

   */

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    final Scaffold scaffold =
        Scaffold(
          appBar: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: _buildAppBar(context),), 
          body: _buildColumn());
    return scaffold;
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 5.0,
      title: const Text('Chat utilizando el protocolo MQTT'),
      backgroundColor: Colors.greenAccent,
    );
  }

  Widget _buildColumn() {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Column(
        children: <Widget>[
          _buildConnectionStateText(
              _prepareStateMessageFrom(currentAppState.getAppConnectionState)),
          _buildEditableColumn(),
          _buildScrollableTextWith(currentAppState.getHistoryText),
          Center(
            child: Text(
              'ID del dispositivo $deviceid, usuario $nikname',
              style: TextStyle(color: Colors.lightGreen),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          _buildTextFieldWith(_hostTextController, 'Dirección del broker',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 5),
          _buildTextFieldWith(
              _topicTextController,
              'Tópico para suscribirse o escuchar',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 5),
          _buildTextFieldWith(_nameTextController, 'Escribe tu Nickname',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 5),
          _buildPublishMessageRow(),
          const SizedBox(height: 5),
          _buildConnecteButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  Widget _buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: _buildTextFieldWith(_messageTextController,
              'Escribe un mensaje', currentAppState.getAppConnectionState),
        ),
        _buildSendButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              color: _dinamycStatusColor(status),
              child: Text(status,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  Color _dinamycStatusColor(String status) {
    if (status == 'Desconectado') {
      return Colors.deepOrangeAccent;
    } else if (status == 'Conectando') {
      return Colors.yellow;
    } else {
      return Colors.lightBlue;
    }
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (controller == _messageTextController &&
        state == MQTTAppConnectionState.connected) {
      shouldEnable = true;
    } else if ((controller == _hostTextController &&
            state == MQTTAppConnectionState.disconnected) ||
        (controller == _topicTextController &&
            state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = false; // Se deshabilito para que aparezcan por defecto
      // el topico y el host
    } else if (controller == _nameTextController &&
        state == MQTTAppConnectionState.disconnected) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildScrollableTextWith(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          width: 400,
          height: 200,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RaisedButton(
            color: Colors.lightBlueAccent,
            child: const Text('Conectar'),
            onPressed: state == MQTTAppConnectionState.disconnected
                ? _configureAndConnect
                : null, //
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: RaisedButton(
            color: Colors.redAccent,
            child: const Text('Desconectar'),
            onPressed: state == MQTTAppConnectionState.connected
                ? _disconnect
                : null, //
          ),
        ),
      ],
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return RaisedButton(
      color: Colors.green,
      child: const Text('Enviar'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }

  // Utility functions
  String _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return 'Conectado';
      case MQTTAppConnectionState.connecting:
        return 'Conectando';
      case MQTTAppConnectionState.disconnected:
        return 'Desconectado';
    }
  }

  void _configureAndConnect() {
    // TODO: Use UUID
    // String osPrefix = 'Flutter_iOS';
    // if(Platform.isAndroid){
    //   osPrefix = 'Flutter_Android';
    // }

    nikname = _nameTextController.text;
    manager = MQTTManager(
        host: _hostTextController.text,
        topic: _topicTextController.text,
        identifier: deviceid,
        // identifier: osPrefix,
        state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  void _disconnect() {
    manager.disconnect();
  }

  void _publishMessage(String text) {
    String osPrefix = '_iOS';
    if (Platform.isAndroid) {
      osPrefix = '_Android';
    }
    final String message = '$nikname  desde  $osPrefix dice:  $text';
    manager.publish(message);
    _messageTextController.clear();
  }
}
