import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController _controller;
  late LatLng _selectedLatLng;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _selectedLatLng = LatLng(widget.initialLat, widget.initialLng);
    _latController.text = widget.initialLat.toString();
    _lngController.text = widget.initialLng.toString();
  }

  Future<void> _moveCameraToAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        _controller.animateCamera(
          CameraUpdate.newLatLng(LatLng(loc.latitude, loc.longitude)),
        );
        _updateLocation(LatLng(loc.latitude, loc.longitude));
      }
    } catch (e) {
      logger.e("Geocoding error", error: e);
    }
  }

  void _updateLocation(LatLng latLng) {
    setState(() {
      _selectedLatLng = latLng;
      _latController.text = latLng.latitude.toStringAsFixed(6);
      _lngController.text = latLng.longitude.toStringAsFixed(6);
    });
  }

  void _applyManualLatLng() {
    try {
      final lat = double.parse(_latController.text);
      final lng = double.parse(_lngController.text);
      final latLng = LatLng(lat, lng);
      _controller.animateCamera(CameraUpdate.newLatLng(latLng));
      _updateLocation(latLng);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid coordinates")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pick Location")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TypeAheadField<String>(
              controller: _searchController,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Search location...",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed:
                          () => _moveCameraToAddress(_searchController.text),
                    ),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                // Fake suggestions for simplicity (you can use real API like Places API)
                return pattern.length > 2
                    ? ["$pattern City", "$pattern Street", "$pattern Building"]
                    : [];
              },
              itemBuilder:
                  (context, suggestion) => ListTile(title: Text(suggestion)),
              onSelected: (suggestion) => _moveCameraToAddress(suggestion),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Latitude'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Longitude'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: _applyManualLatLng,
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLatLng,
                zoom: 14,
              ),
              onMapCreated: (controller) => _controller = controller,
              onTap: (latLng) => _updateLocation(latLng),
              markers: {
                Marker(
                  markerId: MarkerId("selected"),
                  position: _selectedLatLng,
                  infoWindow: InfoWindow(title: "Selected"),
                ),
              },
            ),
          ),
          ElevatedButton(
            child: Text("Confirm Location"),
            onPressed: () {
              Navigator.pop(context, {
                'lat': _selectedLatLng.latitude,
                'lng': _selectedLatLng.longitude,
              });
            },
          ),
        ],
      ),
    );
  }
}
