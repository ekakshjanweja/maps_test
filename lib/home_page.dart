import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:ticktech_map_assignment/widgets/custom_input.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final locationController = Location();

  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};

  static const sourceLocation = LatLng(28.612894, 77.229446);
  static const destinationLocation = LatLng(28.444, 77.45423);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => await initMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        padding: EdgeInsets.symmetric(
          vertical: currentHeight * 0.02,
          horizontal: currentWidth * 0.02,
        ),
        child: _buildBody(context),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;
    return AppBar(
      leading: const Icon(Icons.menu),
      centerTitle: true,
      title: const Text('Flutter Map Demo'),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  _buildBody(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        children: [
          CustomInput(
            icon: Transform.rotate(
              angle: pi,
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
          ),
          SizedBox(height: currentHeight * 0.02),
          CustomInput(
            icon: Transform.rotate(
              angle: 0,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 48,
              ),
            ),
          ),
          SizedBox(height: currentHeight * 0.02),
          currentPosition == null
              ? const CircularProgressIndicator()
              : Container(
                  width: currentWidth,
                  height: currentHeight * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildGoogleMaps(),
                  ),
                ),
        ],
      ),
    );
  }

  _buildGoogleMaps() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentPosition == null ? sourceLocation : currentPosition!,
        zoom: 13.5,
      ),
      markers: {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentPosition!,
        ),
        const Marker(
          markerId: MarkerId("sourceLocation"),
          position: sourceLocation,
        ),
        const Marker(
          markerId: MarkerId("sourceLocation"),
          position: destinationLocation,
        ),
      },
      polylines: Set<Polyline>.of(polylines.values),
    );
  }

  Future<void> getLocationUpdates() async {
    bool isServiceEnabled;

    PermissionStatus permissionStatus;

    isServiceEnabled = await locationController.serviceEnabled();

    if (isServiceEnabled) {
      isServiceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionStatus = await locationController.hasPermission();

    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await locationController.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
      }
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();

    final result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCKexzRg44EKvLtQMLu389EiWvJ0yhGxSo",
      PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
    );

    if (result.points.isNotEmpty) {
      return result.points
          .map((pt) => LatLng(pt.latitude, pt.longitude))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> generatePolylineFromPoints(
      List<LatLng> polylineCoordiates) async {
    const id = PolylineId("polyline");
    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordiates,
      width: 3,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<void> initMap() async {
    await getLocationUpdates();
    final coordinates = await fetchPolylinePoints();
    generatePolylineFromPoints(coordinates);
  }
}
