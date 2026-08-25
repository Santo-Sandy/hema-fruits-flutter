import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hema_fruits/core/providers/location_provider.dart';

/// Opens the location picker bottom sheet.
/// Call this from any screen to allow the user to pick a delivery address.
Future<void> showLocationPickerSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(Icons.location_on, color: Color(0xFF1E5E42), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Choose Delivery Location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E1A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1E5E42),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF1E5E42),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(icon: Icon(Icons.gps_fixed, size: 14), text: 'Auto Detect'),
                    Tab(icon: Icon(Icons.search_rounded, size: 14), text: 'Type / Search'),
                    Tab(icon: Icon(Icons.map_rounded, size: 14), text: 'From Map'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tab View Pages
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _AutoDetectTab(),
                    _TypeSearchTab(),
                    _MapPickerTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Tab 1: Auto Detect
// ─────────────────────────────────────────────
class _AutoDetectTab extends StatefulWidget {
  const _AutoDetectTab();

  @override
  State<_AutoDetectTab> createState() => _AutoDetectTabState();
}

class _AutoDetectTabState extends State<_AutoDetectTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _detecting = false;
  String _status = '';
  DeliveryLocation? _detected;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    setState(() {
      _detecting = true;
      _detected = null;
    });
    final provider = context.read<LocationProvider>();
    final result = await provider.autoDetectLocation(
      onStatusUpdate: (s) {
        if (mounted) setState(() => _status = s);
      },
    );
    if (mounted) {
      setState(() {
        _detecting = false;
        _detected = result;
        _status = result != null ? 'Location Detected Successfully!' : 'Could not detect location.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Radar Scan Animation
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse rings
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      _ring(160 * _pulseAnim.value, _detecting ? 0.15 : 0.05),
                      _ring(130 * _pulseAnim.value, _detecting ? 0.20 : 0.08),
                      _ring(100 * _pulseAnim.value, _detecting ? 0.25 : 0.12),
                    ],
                  ),
                ),
                // Center icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _detecting ? const Color(0xFF1E5E42) : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E5E42).withValues(alpha: _detecting ? 0.4 : 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.gps_fixed_rounded,
                    size: 32,
                    color: _detecting ? Colors.white : const Color(0xFF1E5E42),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _detecting ? 'Detecting your location...' : 'Auto Detect Location',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _detecting
                ? _status
                : 'We will use your device GPS to find the best delivery slot near you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 28),

          // Detected location card
          if (_detected != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E5E42).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF1E5E42), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _detected!.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_detected!.addressLine}, ${_detected!.city} - ${_detected!.pincode}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5E42),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⚡ Express Delivery Serviceable', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<LocationProvider>().updateLocation(_detected!);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5E42),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CONFIRM THIS LOCATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (!_detecting)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _detect,
                icon: const Icon(Icons.gps_fixed, color: Colors.white),
                label: const Text('DETECT MY LOCATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5E42),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ring(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1E5E42).withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2: Type / Search Address
// ─────────────────────────────────────────────
class _TypeSearchTab extends StatefulWidget {
  const _TypeSearchTab();

  @override
  State<_TypeSearchTab> createState() => _TypeSearchTabState();
}

class _TypeSearchTabState extends State<_TypeSearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _addressLineCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  List<DeliveryLocation> _suggestions = [];
  DeliveryLocation? _selectedFromSearch;
  bool _showManualForm = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _addressLineCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final provider = context.read<LocationProvider>();
    setState(() {
      _suggestions = provider.searchLocations(query);
      _selectedFromSearch = null;
    });
  }

  void _onSelectSuggestion(DeliveryLocation loc) {
    setState(() {
      _selectedFromSearch = loc;
      _searchCtrl.text = loc.displayName;
      _suggestions = [];
      _showManualForm = false;
    });
  }

  void _confirmSelected() {
    if (_selectedFromSearch != null) {
      context.read<LocationProvider>().updateLocation(_selectedFromSearch!);
      Navigator.pop(context);
    }
  }

  void _confirmManual() {
    final city = _cityCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();
    final addressLine = _addressLineCtrl.text.trim();

    if (city.isEmpty || pincode.isEmpty || addressLine.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in address, city and pincode')),
      );
      return;
    }

    final loc = DeliveryLocation(
      displayName: '$addressLine, $city',
      addressLine: addressLine,
      landmark: _landmarkCtrl.text.trim(),
      city: city,
      state: 'Karnataka',
      pincode: pincode,
      latitude: 12.9716,
      longitude: 77.5946,
      mode: LocationDetectionMode.typed,
    );
    context.read<LocationProvider>().updateLocation(loc);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E5E42).withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search area, colony, street, pincode...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E5E42)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // Suggestions
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (_, i) {
                  final loc = _suggestions[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: Color(0xFF1E5E42)),
                    title: Text(loc.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('${loc.city} • ${loc.pincode}', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.north_west, size: 14, color: Colors.grey),
                    onTap: () => _onSelectSuggestion(loc),
                    dense: true,
                  );
                },
              ),
            ),
          ],

          // Selected location card
          if (_selectedFromSearch != null) ...[
            const SizedBox(height: 16),
            _buildSelectedCard(_selectedFromSearch!),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5E42),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('DELIVER HERE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR ENTER MANUALLY', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 12),

          // Toggle manual form
          InkWell(
            onTap: () => setState(() => _showManualForm = !_showManualForm),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E5E42).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_location_alt_outlined, color: Color(0xFF1E5E42), size: 20),
                  const SizedBox(width: 10),
                  const Text('Enter Full Address Manually', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  Icon(_showManualForm ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          if (_showManualForm) ...[
            const SizedBox(height: 14),
            _buildTextField(_addressLineCtrl, 'Address Line (House No, Street)', Icons.home_outlined),
            const SizedBox(height: 10),
            _buildTextField(_landmarkCtrl, 'Landmark (Optional)', Icons.place_outlined),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(_cityCtrl, 'City', Icons.location_city_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_pincodeCtrl, 'Pincode', Icons.pin_drop_outlined, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5E42),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SAVE & DELIVER HERE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1E5E42), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _buildSelectedCard(DeliveryLocation loc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E5E42).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF1E5E42), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${loc.city} - ${loc.pincode}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 3: Map Picker
// ─────────────────────────────────────────────
class _MapPickerTab extends StatefulWidget {
  const _MapPickerTab();

  @override
  State<_MapPickerTab> createState() => _MapPickerTabState();
}

class _MapPickerTabState extends State<_MapPickerTab> {
  // Simulated map center (in a real app this would be actual map coords)
  double _centerLat = 12.9116;
  double _centerLng = 77.6741;
  Offset _pinOffset = const Offset(0, 0);
  String _resolvedAddress = 'HSR Layout Sector 1, Bengaluru - 560102';
  String _resolvedCity = 'Bengaluru';
  String _resolvedPincode = '560102';
  bool _isResolving = false;
  double _zoom = 1.0;

  static const _locations = [
    {'area': 'HSR Layout', 'lat': 12.9116, 'lng': 77.6741, 'pincode': '560102', 'city': 'Bengaluru'},
    {'area': 'Koramangala', 'lat': 12.9352, 'lng': 77.6245, 'pincode': '560095', 'city': 'Bengaluru'},
    {'area': 'Indiranagar', 'lat': 12.9716, 'lng': 77.6412, 'pincode': '560038', 'city': 'Bengaluru'},
    {'area': 'Whitefield', 'lat': 12.9700, 'lng': 77.7499, 'pincode': '560066', 'city': 'Bengaluru'},
    {'area': 'Jayanagar', 'lat': 12.9299, 'lng': 77.5820, 'pincode': '560041', 'city': 'Bengaluru'},
  ];

  void _onPanUpdate(DragUpdateDetails details, Size mapSize) {
    setState(() {
      _pinOffset = Offset(
        (_pinOffset.dx + details.delta.dx).clamp(-mapSize.width / 2 + 40, mapSize.width / 2 - 40),
        (_pinOffset.dy + details.delta.dy).clamp(-mapSize.height / 2 + 40, mapSize.height / 2 - 40),
      );
      // Simulate lat/lng update based on drag offset
      _centerLat = 12.9116 + (_pinOffset.dy * -0.001 / _zoom);
      _centerLng = 77.6741 + (_pinOffset.dx * 0.001 / _zoom);
    });
    _resolveAddress();
  }

  void _onSelectArea(Map location) {
    setState(() {
      _centerLat = (location['lat'] as num).toDouble();
      _centerLng = (location['lng'] as num).toDouble();
      _resolvedAddress = '${location['area']}, ${location['city']}  - ${location['pincode']}';
      _resolvedCity = location['city'] as String;
      _resolvedPincode = location['pincode'] as String;
      _pinOffset = const Offset(0, 0);
    });
  }

  Future<void> _resolveAddress() async {
    setState(() => _isResolving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // Find nearest location stub
    final nearest = _locations.reduce((a, b) {
      final dA = math.pow(_centerLat - (a['lat'] as num), 2) + math.pow(_centerLng - (a['lng'] as num), 2);
      final dB = math.pow(_centerLat - (b['lat'] as num), 2) + math.pow(_centerLng - (b['lng'] as num), 2);
      return dA < dB ? a : b;
    });
    setState(() {
      _resolvedAddress = '${nearest['area']}, ${nearest['city']} - ${nearest['pincode']}';
      _resolvedCity = nearest['city'] as String;
      _resolvedPincode = nearest['pincode'] as String;
      _isResolving = false;
    });
  }

  void _confirmLocation() {
    final loc = DeliveryLocation(
      displayName: _resolvedAddress,
      addressLine: _resolvedAddress,
      landmark: '',
      city: _resolvedCity,
      state: 'Karnataka',
      pincode: _resolvedPincode,
      latitude: _centerLat,
      longitude: _centerLng,
      mode: LocationDetectionMode.mapPicker,
    );
    context.read<LocationProvider>().updateLocation(loc);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Area quick-select chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _locations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final loc = _locations[i];
              final isSelected = _resolvedAddress.contains(loc['area'] as String);
              return GestureDetector(
                onTap: () => _onSelectArea(loc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E5E42) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1E5E42) : Colors.grey.withValues(alpha: 0.3),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                  ),
                  child: Text(
                    loc['area'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Interactive Map Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanUpdate: (d) => _onPanUpdate(d, size),
                    child: Stack(
                      children: [
                        // Map background (custom painted grid)
                        CustomPaint(
                          size: size,
                          painter: _MapGridPainter(
                            centerLat: _centerLat,
                            centerLng: _centerLng,
                            zoom: _zoom,
                          ),
                        ),

                        // Draggable Pin
                        Center(
                          child: Transform.translate(
                            offset: _pinOffset,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E5E42),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_centerLat.toStringAsFixed(4)}, ${_centerLng.toStringAsFixed(4)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Icon(Icons.location_pin, color: Color(0xFFE53935), size: 44),
                                const SizedBox(height: 4),
                                Container(
                                  width: 10,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Zoom Controls
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Column(
                            children: [
                              _zoomButton(Icons.add, () => setState(() => _zoom = (_zoom + 0.25).clamp(0.5, 3.0))),
                              const SizedBox(height: 6),
                              _zoomButton(Icons.remove, () => setState(() => _zoom = (_zoom - 0.25).clamp(0.5, 3.0))),
                            ],
                          ),
                        ),

                        // Compass
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.navigation_rounded, size: 18, color: Color(0xFF1E5E42)),
                          ),
                        ),

                        // Hint overlay
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '📌 Drag to move pin & select location',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Resolved address bottom bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, -2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF1E5E42), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _isResolving
                        ? const Text('Resolving address...', style: TextStyle(fontSize: 12, color: Colors.grey))
                        : Text(_resolvedAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isResolving ? null : _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5E42),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('CONFIRM PIN LOCATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1E5E42)),
      ),
    );
  }
}

/// Custom painter for the fake map grid
class _MapGridPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final double zoom;

  const _MapGridPainter({required this.centerLat, required this.centerLng, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFE8EFE8);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFD0DDD0)
      ..strokeWidth = 0.8;

    const gridCount = 12;
    for (int i = 0; i <= gridCount; i++) {
      final x = size.width * i / gridCount;
      final y = size.height * i / gridCount;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Road-like shapes
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8 * zoom;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.72), Offset(size.width, size.height * 0.72), roadPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.55, 0), Offset(size.width * 0.55, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.78, 0), Offset(size.width * 0.78, size.height), roadPaint);

    // Park blocks
    final parkPaint = Paint()..color = const Color(0xFFB8D8B8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height * 0.12, size.width * 0.18, size.height * 0.18), const Radius.circular(6)),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.60, size.height * 0.60, size.width * 0.22, size.height * 0.15), const Radius.circular(6)),
      parkPaint,
    );

    // Building blocks
    final blockPaint = Paint()..color = const Color(0xFFCDD9CD);
    final blockRects = [
      Rect.fromLTWH(size.width * 0.34, size.height * 0.10, size.width * 0.17, size.height * 0.20),
      Rect.fromLTWH(size.width * 0.60, size.height * 0.10, size.width * 0.15, size.height * 0.20),
      Rect.fromLTWH(size.width * 0.08, size.height * 0.38, size.width * 0.18, size.height * 0.14),
      Rect.fromLTWH(size.width * 0.34, size.height * 0.38, size.width * 0.17, size.height * 0.14),
      Rect.fromLTWH(size.width * 0.60, size.height * 0.38, size.width * 0.15, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.08, size.height * 0.60, size.width * 0.18, size.height * 0.09),
      Rect.fromLTWH(size.width * 0.34, size.height * 0.60, size.width * 0.17, size.height * 0.09),
    ];
    for (final r in blockRects) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), blockPaint);
    }

    // Water body
    final waterPaint = Paint()..color = const Color(0xFFB3CFFE);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.82, size.height * 0.25), width: size.width * 0.12, height: size.height * 0.10),
      waterPaint,
    );

    // Coordinates watermark
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${centerLat.toStringAsFixed(3)}°N, ${centerLng.toStringAsFixed(3)}°E  |  Zoom ${zoom.toStringAsFixed(1)}x',
        style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(8, size.height - 22));
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) =>
      oldDelegate.centerLat != centerLat ||
      oldDelegate.centerLng != centerLng ||
      oldDelegate.zoom != zoom;
}
