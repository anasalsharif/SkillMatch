import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationView extends StatefulWidget {
  final double lag, lat;
  const LocationView({super.key, required this.lag, required this.lat});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant LocationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lat != oldWidget.lat || widget.lag != oldWidget.lag) {
      _moveCameraToNewPosition();
    }
  }

  void _moveCameraToNewPosition() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.lat, widget.lag)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.lat, widget.lag),
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: {
            Marker(
              markerId: MarkerId('user_location'),
              position: LatLng(widget.lat, widget.lag),
              infoWindow: InfoWindow(title: "Selected Location"),
            ),
          },
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          myLocationEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}
