import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/services/location_service.dart';
import 'package:skillmatch_platform/services/organization_service.dart';
import 'package:skillmatch_platform/widgets/web_layouts/web_form_components.dart';

class WebMapScreen extends StatefulWidget {
  final String token;

  const WebMapScreen({super.key, required this.token});

  @override
  State<WebMapScreen> createState() => _WebMapScreenState();
}

class _WebMapScreenState extends State<WebMapScreen> {
  final _logger = Logger();
  LatLng? _userLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  GoogleMapController? _mapController;

  late final LocationService _locationService;
  late final OrganizationService _orgService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(token: widget.token);
    _orgService = OrganizationService(token: widget.token);
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _getUserLocation();
      await _loadOrganizationMarkers();
    } catch (e) {
      _logger.e("Error initializing map", error: e);
      setState(() {
        _errorMessage =
            "Failed to load map data. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              "Location services are disabled. Please enable them to use the map.";
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage =
                "Location permissions are denied. Please grant permission to use the map.";
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              "Location permissions are permanently denied. Please enable them in settings.";
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = currentLatLng;
        _markers.add(
          Marker(
            markerId: const MarkerId("user"),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: "Your Location"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      _logger.e("Error getting user location", error: e);
      setState(() {
        _errorMessage = "Failed to get your location. Using default location.";
        _userLocation = const LatLng(32.150146, 35.253834); // Default location
        _isLoading = false;
      });
    }
  }

  Future<void> _onMarkerTapped(String organizationId) async {
    try {
      final data = await _orgService.getOrganizationProfile(
        organizationId: organizationId,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['name'] ?? 'Organization',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['industry'] != null) ...[
                    _buildInfoRow(Icons.category, 'Industry', data['industry']),
                    const SizedBox(height: 8),
                  ],
                  if (data['email'] != null) ...[
                    _buildInfoRow(Icons.email, 'Email', data['email']),
                    const SizedBox(height: 8),
                  ],
                  if (data['description'] != null) ...[
                    _buildInfoRow(
                      Icons.description,
                      'About',
                      data['description'],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      _logger.e('Failed to load organization details', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load organization info'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Future<void> _loadOrganizationMarkers() async {
    try {
      final locations = await _locationService.getAllCompaniesLocations();
      _logger.d("Fetched locations: $locations");

      for (int i = 0; i < locations.length; i++) {
        final org = locations[i];
        final lat = (org['lat'] as num).toDouble();
        final lng = (org['lng'] as num).toDouble();
        final name = org['organization']['name'] ?? 'Organization #$i';

        _markers.add(
          Marker(
            markerId: MarkerId(org['organization']['id']),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            onTap: () => _onMarkerTapped(org['organization']['id']),
          ),
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logger.e("Failed to load organization markers", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load organization locations'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _refreshMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _markers.clear();
    });
    await _initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Section
          Expanded(
            child: WebCard(
              child: Column(
                children: [
                  // Map Header with Refresh Button
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Organization Locations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: _refreshMap,
                              tooltip: 'Refresh Map',
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Map Content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMapContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading map...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Map Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshMap,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_userLocation == null) {
      return const Center(child: Text('Unable to determine location'));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 12.0),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: true,
      mapType: MapType.normal,
    );
  }
}
