import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCS DHT Sensor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DhtSensorPage(),
    );
  }
}

class DhtSensorPage extends StatefulWidget {
  @override
  _DhtSensorPageState createState() => _DhtSensorPageState();
}

class _DhtSensorPageState extends State<DhtSensorPage> {
  bool isLoading = true;
  double temperature = 0.0;
  double humidity = 0.0;
  StreamSubscription? sensorSubscription;

  @override
  void initState() {
    super.initState();
    listenToSensorData();
  }

  @override
  void dispose() {
    // Cancel the Firestore subscription when the widget is disposed
    sensorSubscription?.cancel();
    super.dispose();
  }

  void listenToSensorData() {
    sensorSubscription = FirebaseFirestore.instance
        .collection('dht')
        .snapshots()
        .listen((QuerySnapshot snapshots) {
      if (snapshots.docs.isNotEmpty) {
        // Access the first document in the collection
        Map<String, dynamic> data =
            snapshots.docs[0].data() as Map<String, dynamic>;
        setState(() {
          temperature = double.parse(data['temp'].toString());
          humidity = double.parse(data['humidity'].toString());
          isLoading = false;
        });
        print('Real-time data: $data');
      } else {
        print('No documents in the collection!');
        setState(() {
          isLoading = false;
        });
      }
    }, onError: (error) {
      print('Error listening to Firestore data: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MCS DHT Sensor'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: temperature / 40.0,
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Temperature: ${temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 40),
                  CircularProgressIndicator(
                    value: humidity / 100.0,
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Humidity: ${humidity.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
