import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marker_clustering/widgets/custom_painter.dart';

import 'model/place.dart';
import 'dart:ui' as ui;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Google Marker CLustering',
      home: MapSample(),
    );
  }
}

// Clustering maps

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late ClusterManager _manager;
  late ClusterManager _manager2;

  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> markers = {};
  Set<Marker> markers2 = {};

  final CameraPosition _parisCameraPosition =
      const CameraPosition(target: LatLng(48.858265, 2.350107), zoom: 10.0);

  List<Place> items = [
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Restaurant $i',
          isClosed: i % 2 == 0,
          latLng: LatLng(48.858265 - i * 0.001, 2.350107 + i * 0.001)),
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Bar $i',
          latLng: LatLng(48.858265 + i * 0.01, 2.350107 - i * 0.01)),
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Hotel $i',
          latLng: LatLng(48.858265 - i * 0.1, 2.350107 - i * 0.01)),
  ];

  List<Place> items2 = [
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Place $i',
          latLng: LatLng(48.848200 + i * 0.001, 2.319124 + i * 0.001)),
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Test $i',
          latLng: LatLng(48.858265 + i * 0.1, 2.350107 + i * 0.1)),
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Test2 $i',
          latLng: LatLng(48.858265 + i * 1, 2.350107 + i * 1)),
  ];

  @override
  void initState() {
    _manager = ClusterManager<Place>(items, _updateMarkers,
        markerBuilder: _getMarkerBuilder(Colors.red));

    _manager2 = ClusterManager<Place>(items2, _updateMarkers2,
        markerBuilder: _getMarkerBuilder(Colors.blue));
    super.initState();
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  void _updateMarkers2(Set<Marker> markers) {
    setState(() {
      markers2 = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          initialCameraPosition: _parisCameraPosition,
          markers: markers..addAll(markers2),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _manager.setMapId(controller.mapId);
            _manager2.setMapId(controller.mapId);
          },
          onCameraMove: (position) {
            _manager.onCameraMove(position);
            _manager2.onCameraMove(position);
          },
          onCameraIdle: () {
            _manager.updateMap();
            _manager2.updateMap();
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // _manager.setItems(<Place>[
          //   for (int i = 0; i < 30; i++)
          //     Place(
          //         name: 'New Place ${DateTime.now()} $i',
          //         latLng: LatLng(48.858265 + i * 0.01, 2.350107))
          // ]);
        },
        child: const Icon(Icons.update),
      ),
    );
  }

  Future<Marker> Function(Cluster<Place>) _getMarkerBuilder(Color color) =>
      (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            print('---- $cluster');
            cluster.items.forEach((p) => print(p));
          },
          icon: cluster.isMultiple
              ? await _getMarkerBitmap(115, color,
                  text: cluster.count.toString())
              : await _getMarkerBitmapWithLabel(context, cluster.items.first.name),
        );
      };

  Future<BitmapDescriptor> _getMarkerBitmapWithLabel(BuildContext context, String label) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  
  // Load the original marker bitmap
  final ByteData data = await DefaultAssetBundle.of(context).load("assets/images/location.png");
  final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final ui.Image markerImage = (await codec.getNextFrame()).image;
  
  // Draw the marker icon onto the canvas
  canvas.drawImage(markerImage, Offset.zero, Paint());
  
  // Draw the label on the canvas
  const double labelFontSize = 27.0;
  const double labelX = 20.0;
  const double labelY = 10.0;
  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(color: Colors.black, fontSize: labelFontSize, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, const Offset(labelX, labelY));
  
  final ui.Image markerIcon = await pictureRecorder.endRecording().toImage(
    markerImage.width,
    markerImage.height,
  );

  final ByteData? byteData = await markerIcon.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}


  Future<BitmapDescriptor> _getMarkerBitmap(int size, Color color,
      {String? text}) async {
    if (kIsWeb) size = (size / 2).floor();

    CustomPaint(
      painter: MyCustomPainter(),
      size: const Size(200, 200), // Replace this with your desired size
    );

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = color;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.4, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 3.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
            fontSize: size / 3,
            color: Colors.white,
            fontWeight: FontWeight.normal),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png) as ByteData;

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
