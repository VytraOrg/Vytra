import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../core/config/secrets.dart';
import '../../../../core/design_system.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? shopName;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.shopName,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  Timer? _debounce;

  String? _resolvedAddress;
  String? _resolvedDistrict;
  String? _resolvedState;
  String? _resolvedPincode;

  @override
  void initState() {
    super.initState();
    // Default to Kolkata center if no initial coordinate provided or if it's 0.0
    final bool hasValidInitial = widget.initialLatitude != null &&
        widget.initialLatitude != 0.0 &&
        widget.initialLongitude != null &&
        widget.initialLongitude != 0.0;

    _selectedLocation = LatLng(
      hasValidInitial ? widget.initialLatitude! : 22.5726,
      hasValidInitial ? widget.initialLongitude! : 88.3639,
    );
    _updateMarker(_selectedLocation);
    // Reverse geocode initial position to pre-populate text field
    _reverseGeocode(_selectedLocation);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchAddress(query);
    });
  }

  void _updateMarker(LatLng position, {String? customTitle}) {
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('shop_location'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
            _reverseGeocode(newPosition);
          },
          infoWindow: InfoWindow(
            title: customTitle ?? widget.shopName ?? _resolvedAddress ?? 'Shop Location',
            snippet: 'Drag to refine location',
          ),
        ),
      );
    });
  }

  Map<String, String> _parseAddressComponents(List<dynamic> components) {
    String district = '';
    String state = '';
    String pincode = '';
    String locality = '';
    String adminArea2 = '';
    String adminArea3 = '';

    for (var comp in components) {
      final types = List<String>.from(comp['types'] ?? []);
      if (types.contains('postal_code')) {
        pincode = comp['long_name'] ?? '';
      } else if (types.contains('administrative_area_level_1')) {
        state = comp['long_name'] ?? '';
      } else if (types.contains('administrative_area_level_2')) {
        adminArea2 = comp['long_name'] ?? '';
      } else if (types.contains('administrative_area_level_3')) {
        adminArea3 = comp['long_name'] ?? '';
      } else if (types.contains('locality')) {
        locality = comp['long_name'] ?? '';
      }
    }

    // In India (especially West Bengal), administrative_area_level_2 is often the Division (e.g., Presidency Division)
    // and administrative_area_level_3 is the actual District (e.g., South 24 Parganas).
    if (adminArea2.toLowerCase().contains('division')) {
      district = adminArea3.isNotEmpty ? adminArea3 : adminArea2;
    } else {
      district = adminArea2.isNotEmpty ? adminArea2 : (adminArea3.isNotEmpty ? adminArea3 : locality);
    }

    return {
      'district': district,
      'state': state,
      'pincode': pincode,
    };
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${Secrets.googleMapsApiKey}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final firstResult = data['results'][0];
          final components = firstResult['address_components'] as List<dynamic>? ?? [];
          final parsed = _parseAddressComponents(components);

          setState(() {
            _resolvedAddress = firstResult['formatted_address'];
            _resolvedDistrict = parsed['district'];
            _resolvedState = parsed['state'];
            _resolvedPincode = parsed['pincode'];
            _searchController.text = _resolvedAddress ?? '';
            
            // Re-update marker to show resolved address in InfoWindow
            _updateMarker(position);
          });
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=${Secrets.googleMapsApiKey}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          setState(() {
            _searchResults = data['results'];
          });
        } else {
          setState(() {
            _searchResults = [];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error_message'] ?? 'No locations found'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to load geocoding data');
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing search: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(dynamic result) {
    final geometry = result['geometry'];
    if (geometry != null && geometry['location'] != null) {
      final lat = (geometry['location']['lat'] as num).toDouble();
      final lng = (geometry['location']['lng'] as num).toDouble();
      final position = LatLng(lat, lng);

      final components = result['address_components'] as List<dynamic>? ?? [];
      final parsed = _parseAddressComponents(components);

      setState(() {
        _resolvedAddress = result['formatted_address'];
        _resolvedDistrict = parsed['district'];
        _resolvedState = parsed['state'];
        _resolvedPincode = parsed['pincode'];
        
        _searchController.text = _resolvedAddress ?? '';
        _searchResults = [];
        
        // Update marker with new position and address title
        _updateMarker(position);
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 17.0),
        ),
      );
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied, we cannot request permissions.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      // Update marker and camera
      _updateMarker(latLng);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 17.0),
        ),
      );

      // Reverse geocode to get address details
      await _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Shop Location', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            onTap: (position) {
              _updateMarker(position);
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(position),
              );
              _reverseGeocode(position);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          
          // Bottom confirmation card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_pin, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Shop Coordinates',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('LATITUDE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedLocation.latitude.toStringAsFixed(6),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('LONGITUDE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedLocation.longitude.toStringAsFixed(6),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'latLng': _selectedLocation,
                          'address': _resolvedAddress,
                          'district': _resolvedDistrict,
                          'state': _resolvedState,
                          'pincode': _resolvedPincode,
                        });
                      },
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Guide Banner at the top (positioned below the search bar)
          Positioned(
            top: 82,
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.primary.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap on the map or drag the pin to set your exact shop location.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: PointerInterceptor(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search for shop location...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: _searchAddress,
                        ),
                      ),
                      if (_isSearching)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _resolvedAddress = null;
                              _resolvedDistrict = null;
                              _resolvedState = null;
                              _resolvedPincode = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Suggestions Dropdown Overlay
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 74,
              left: 16,
              right: 16,
              child: PointerInterceptor(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          title: Text(
                            result['formatted_address'] ?? 'Unknown location',
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Current Location Button
          Positioned(
            bottom: 245,
            right: 16,
            child: PointerInterceptor(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoadingLocation ? null : _getCurrentLocation,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
