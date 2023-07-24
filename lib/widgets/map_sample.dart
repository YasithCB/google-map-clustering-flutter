import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/place.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MapSampleState();
  }
}

class _MapSampleState extends State<MapSample> {
  late ClusterManager _manager;

  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> markers = Set();

  final CameraPosition _parisCameraPosition =
      const CameraPosition(target: LatLng(48.856613, 2.352222), zoom: 12.0);

  List<Place> items = [
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Place $i',
          latLng: LatLng(48.848200 + i * 0.001, 2.319124 + i * 0.001)),
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
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Test $i',
          latLng: LatLng(66.160507 + i * 0.1, -153.369141 + i * 0.1)),
    for (int i = 0; i < 10; i++)
      Place(
          name: 'Test2 $i',
          latLng: LatLng(-36.848461 + i * 1, 169.763336 + i * 1)),
  ];

  @override
  void initState() {
    _manager = _initClusterManager();
    super.initState();
  }

  ClusterManager _initClusterManager() {
    return ClusterManager<Place>(items, _updateMarkers,
        markerBuilder: _markerBuilder);
  }

  void _updateMarkers(Set<Marker> markers) {
    if (kDebugMode) {
      print('Updated ${markers.length} markers');
    }
    setState(() {
      this.markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
          onTap: (location) {
            if (kDebugMode) {
              print('${location.longitude} - ${location.latitude}');
            }
            setState(() {
              items.add(
                Place(
                  name: 'Custom Place',
                  latLng: LatLng(location.longitude, location.latitude),
                ),
              );
              _initClusterManager();
            });
          },
          mapType: MapType.normal,
          initialCameraPosition: _parisCameraPosition,
          markers: markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _manager.setMapId(controller.mapId);
          },
          onCameraMove: _manager.onCameraMove,
          onCameraIdle: _manager.updateMap),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _manager.setItems(<Place>[
            for (int i = 0; i < 30; i++)
              Place(
                  name: 'New Place ${DateTime.now()} $i',
                  latLng: LatLng(48.858265 + i * 0.01, 2.350107))
          ]);
        },
        child: const Icon(Icons.update),
      ),
    );
  }

  Future<Marker> Function(Cluster<Place>) get _markerBuilder =>
      (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            if (kDebugMode) {
              print('---- $cluster');
              for (var p in cluster.items) {
                print(p);
              }
            }
          },
          icon: await _getMarkerBitmap(cluster.isMultiple ? 125 : 75,
              text: cluster.isMultiple ? cluster.count.toString() : null),
        );
      };

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {String? text}) async {
    if (kIsWeb) size = (size / 2).floor();

    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = const Color.fromARGB(255, 5, 72, 255);
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

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
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
