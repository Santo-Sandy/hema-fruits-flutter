import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum LocationDetectionMode { autoDetect, typed, mapPicker }

class DeliveryLocation {
  final String displayName;
  final String addressLine;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final LocationDetectionMode mode;
  final bool isServiceable;

  const DeliveryLocation({
    required this.displayName,
    required this.addressLine,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.mode,
    this.isServiceable = true,
  });

  static const DeliveryLocation defaultLocation = DeliveryLocation(
    displayName: 'HSR Layout, Bengaluru',
    addressLine: '12th Main Road, HSR Layout Sector 1',
    landmark: 'Near BDA Complex',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560102',
    latitude: 12.9116,
    longitude: 77.6741,
    mode: LocationDetectionMode.typed,
    isServiceable: true,
  );

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'address_line': addressLine,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'mode': mode.name,
        'is_serviceable': isServiceable,
      };

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      displayName: json['display_name'] ?? '',
      addressLine: json['address_line'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      mode: LocationDetectionMode.values.firstWhere(
        (e) => e.name == (json['mode'] ?? 'typed'),
        orElse: () => LocationDetectionMode.typed,
      ),
      isServiceable: json['is_serviceable'] ?? true,
    );
  }

  DeliveryLocation copyWith({
    String? displayName,
    String? addressLine,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    LocationDetectionMode? mode,
    bool? isServiceable,
  }) {
    return DeliveryLocation(
      displayName: displayName ?? this.displayName,
      addressLine: addressLine ?? this.addressLine,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mode: mode ?? this.mode,
      isServiceable: isServiceable ?? this.isServiceable,
    );
  }
}

class LocationProvider extends ChangeNotifier {
  static const _storageKey = 'delivery_location_v1';

  DeliveryLocation _currentLocation = DeliveryLocation.defaultLocation;
  bool _isDetecting = false;
  String _detectionStatus = '';

  DeliveryLocation get currentLocation => _currentLocation;
  bool get isDetecting => _isDetecting;
  String get detectionStatus => _detectionStatus;
  String get shortDisplay {
    final parts = _currentLocation.displayName.split(',');
    return parts.isNotEmpty ? parts.first.trim() : _currentLocation.displayName;
  }

  LocationProvider() {
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        _currentLocation = DeliveryLocation.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LocationProvider: Failed to load saved location: $e');
    }
  }

  Future<void> _persistLocation(DeliveryLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(loc.toJson()));
    } catch (e) {
      debugPrint('LocationProvider: Failed to persist location: $e');
    }
  }

  /// Updates location from any of the 3 pickers
  Future<void> updateLocation(DeliveryLocation loc) async {
    _currentLocation = loc;
    notifyListeners();
    await _persistLocation(loc);
  }

  /// Simulates auto-detect with stages for UI animation
  Future<DeliveryLocation?> autoDetectLocation({
    void Function(String status)? onStatusUpdate,
  }) async {
    _isDetecting = true;
    _detectionStatus = 'Requesting location access...';
    notifyListeners();
    onStatusUpdate?.call(_detectionStatus);

    await Future.delayed(const Duration(milliseconds: 900));
    _detectionStatus = 'Detecting GPS coordinates...';
    notifyListeners();
    onStatusUpdate?.call(_detectionStatus);

    await Future.delayed(const Duration(milliseconds: 1000));
    _detectionStatus = 'Resolving address from coordinates...';
    notifyListeners();
    onStatusUpdate?.call(_detectionStatus);

    await Future.delayed(const Duration(milliseconds: 800));

    // Simulated detected location result (in a real app, use geolocator + geocoding)
    const detected = DeliveryLocation(
      displayName: 'Koramangala 5th Block, Bengaluru',
      addressLine: '5th Block, Koramangala',
      landmark: 'Near Forum Mall',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560095',
      latitude: 12.9352,
      longitude: 77.6245,
      mode: LocationDetectionMode.autoDetect,
      isServiceable: true,
    );

    _isDetecting = false;
    _detectionStatus = 'Location detected!';
    notifyListeners();
    onStatusUpdate?.call(_detectionStatus);

    return detected;
  }

  /// Search/autocomplete results for typed addresses
  List<DeliveryLocation> searchLocations(String query) {
    if (query.trim().length < 2) return [];
    final q = query.toLowerCase();
    return _allSuggestions
        .where((loc) =>
            loc.displayName.toLowerCase().contains(q) ||
            loc.city.toLowerCase().contains(q) ||
            loc.pincode.contains(q) ||
            loc.addressLine.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  static const List<DeliveryLocation> _allSuggestions = [
    DeliveryLocation(
      displayName: 'Koramangala 5th Block, Bengaluru',
      addressLine: '5th Block, Koramangala',
      landmark: 'Near Forum Mall',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560095',
      latitude: 12.9352, longitude: 77.6245,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Indiranagar 12th Main, Bengaluru',
      addressLine: '12th Main Road, Indiranagar',
      landmark: '',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560038',
      latitude: 12.9716, longitude: 77.6412,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'HSR Layout Sector 1, Bengaluru',
      addressLine: '12th Main Road, HSR Layout Sector 1',
      landmark: 'Near BDA Complex',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560102',
      latitude: 12.9116, longitude: 77.6741,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Whitefield, Bengaluru',
      addressLine: 'Whitefield Main Road',
      landmark: 'Near ITPL Gate',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560066',
      latitude: 12.9700, longitude: 77.7499,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Electronic City Phase 1, Bengaluru',
      addressLine: 'Electronic City Phase 1',
      landmark: 'Near Infosys Campus',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560100',
      latitude: 12.8399, longitude: 77.6770,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Jayanagar 4th Block, Bengaluru',
      addressLine: '4th Block, Jayanagar',
      landmark: 'Near Jayanagar Complex',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560041',
      latitude: 12.9299, longitude: 77.5820,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Malleswaram, Bengaluru',
      addressLine: '15th Cross, Malleswaram',
      landmark: 'Near Mantri Mall',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560003',
      latitude: 13.0030, longitude: 77.5681,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Marathahalli, Bengaluru',
      addressLine: 'Marathahalli Bridge Road',
      landmark: 'Near Brigade Gateway',
      city: 'Bengaluru', state: 'Karnataka', pincode: '560037',
      latitude: 12.9591, longitude: 77.6971,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Anna Nagar, Chennai',
      addressLine: 'Anna Nagar 2nd Avenue',
      landmark: 'Near Tower Park',
      city: 'Chennai', state: 'Tamil Nadu', pincode: '600040',
      latitude: 13.0827, longitude: 80.2101,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Bandra West, Mumbai',
      addressLine: 'Linking Road, Bandra West',
      landmark: 'Near Bandra Station',
      city: 'Mumbai', state: 'Maharashtra', pincode: '400050',
      latitude: 19.0544, longitude: 72.8402,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Banjara Hills, Hyderabad',
      addressLine: 'Road No. 12, Banjara Hills',
      landmark: 'Near GVK One Mall',
      city: 'Hyderabad', state: 'Telangana', pincode: '500034',
      latitude: 17.4138, longitude: 78.4481,
      mode: LocationDetectionMode.typed,
    ),
    DeliveryLocation(
      displayName: 'Rajouri Garden, Delhi',
      addressLine: 'Ring Road, Rajouri Garden',
      landmark: 'Near Metro Station',
      city: 'New Delhi', state: 'Delhi', pincode: '110027',
      latitude: 28.6491, longitude: 77.1218,
      mode: LocationDetectionMode.typed,
    ),
  ];
}
