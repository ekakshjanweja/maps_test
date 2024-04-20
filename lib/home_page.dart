import 'dart:async';
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
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  Location locationController = Location();

  LatLng? currentPosition;

  static const sourceLocation = LatLng(28.600747, 77.029572);
  static const destinationLocation = LatLng(28.5942, 77.0361);

  Map<PolylineId, Polyline> polylines = {};

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) {
      getPolylinePoints().then(
        (coordinates) => generatePolylineFromPoints(coordinates),
      );
    });
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

    locationController.onLocationChanged.listen((LocationData newLocation) {
      if (newLocation.latitude != null && newLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(
            newLocation.latitude!,
            newLocation.longitude!,
          );
          cameraToPosition(currentPosition!);
        });
      }
    });
  }

  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await mapController.future;

    CameraPosition cameraPosition = CameraPosition(
      target: pos,
      zoom: 15,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        cameraPosition,
      ),
    );
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCKexzRg44EKvLtQMLu389EiWvJ0yhGxSo",
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (PointLatLng point in result.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
    } else {
      print(result.errorMessage);
    }

    return polylineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 8,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;

    List<Widget> body = [
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home),
            Text("Home"),
          ],
        ),
      ),
      _buildBody(context),
    ];
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        padding: EdgeInsets.symmetric(
          vertical: currentHeight * 0.02,
          horizontal: currentWidth * 0.02,
        ),
        child: body[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  _buildAppBar(BuildContext context) {
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;
    return AppBar(
      leading: Icon(
        Icons.menu,
        color: Colors.blue.shade800,
      ),
      centerTitle: true,
      title: Text(
        'Location Confirmed',
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade800,
            ),
      ),
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
                size: 40,
              ),
            ),
            placeholder: "Vegas Mall, Sector 14, Dwarka",
          ),
          SizedBox(height: currentHeight * 0.02),
          CustomInput(
            icon: Transform.rotate(
              angle: 0,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
            placeholder: "Dwarka, Sector 12, New Delhi",
          ),
          SizedBox(height: currentHeight * 0.02),
          currentPosition == null
              ? const CircularProgressIndicator()
              : Container(
                  width: currentWidth,
                  height: currentHeight * 0.55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildGoogleMaps(),
                  ),
                ),
          SizedBox(height: currentHeight * 0.02),
          Container(
            alignment: Alignment.center,
            width: currentWidth,
            height: currentHeight * 0.06,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Create Route",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.white,
                  ),
            ),
          )
        ],
      ),
    );
  }

  _buildGoogleMaps() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentPosition == null ? sourceLocation : currentPosition!,
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
        const Marker(
          markerId: MarkerId("sourceLocation"),
          position: sourceLocation,
        ),
        const Marker(
          markerId: MarkerId("destinationLocation"),
          position: destinationLocation,
        ),
      },
      polylines: Set<Polyline>.of(polylines.values),
      onMapCreated: (GoogleMapController controller) {
        mapController.complete(controller);
      },
    );
  }

  _buildBottomBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (value) {
        setState(() {
          _currentIndex = value;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.route), label: "Routes"),
      ],
    );
  }
}
