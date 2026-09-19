import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'cat_fruits';
  String _selectedUnit = 'Kg';
  String _selectedGrade = 'Grade A';
  bool _isOrganic = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _uploadedImageUrl;

  final List<Map<String, String>> _categories = [
    {'id': 'cat_fruits', 'name': 'Fresh Fruits'},
    {'id': 'cat_veggies', 'name': 'Fresh Vegetables'},
    {'id': 'cat_dry_nuts', 'name': 'Dry Fruits & Nuts'},
  ];

  final List<String> _units = ['Kg', 'Tons', 'Boxes', 'Bags', 'g', 'pcs'];
  final List<String> _grades = ['Grade A', 'Export Grade', 'Premium', 'Organic Certified', 'Standard'];

  @override
  void dispose() {
    _titleController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = picked.name;
      _isUploadingImage = true;
    });

    final repo = EcommerceRepository();
    final uploadedUrl = await repo.uploadImage(bytes, picked.name);

    if (mounted) {
      setState(() {
        _isUploadingImage = false;
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          _uploadedImageUrl = uploadedUrl;
        } else {
          // Fallback placeholder with fruit keyword
          _uploadedImageUrl = "https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=600";
        }
      });
    }
  }

  Future<void> _submitStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = await SecureStorageService.getUserData() ?? {};
      final userId = user['_id']?.toString() ?? 'seller_usr';
      final sellerName = user['store_name']?.toString().isNotEmpty == true
          ? user['store_name']
          : (user['name'] ?? 'Hema Verified Seller');

      final qty = double.tryParse(_quantityController.text.trim()) ?? 100.0;
      final price = double.tryParse(_priceController.text.trim()) ?? 150.0;
      final prodId = "prod_${DateTime.now().millisecondsSinceEpoch}";
      final variantId = "var_${DateTime.now().millisecondsSinceEpoch}";

      final imageUrl = _uploadedImageUrl ??
          "https://images.unsplash.com/photo-1553279768-865429fa0078?w=600";

      final productData = {
        "_id": prodId,
        "title": _titleController.text.trim(),
        "slug": _titleController.text.trim().toLowerCase().replaceAll(' ', '-'),
        "category_id": _selectedCategory,
        "subcategory_id": "sub_general",
        "description": _descriptionController.text.trim().isEmpty
            ? 'Fresh agricultural harvest from $sellerName.'
            : _descriptionController.text.trim(),
        "images": [imageUrl],
        "shelf_life_days": 7,
        "storage_instructions": "Store in cool, dry place.",
        "is_organic": _isOrganic,
        "quality_grade": _selectedGrade,
        "origin_region": _locationController.text.trim().isEmpty
            ? 'Ratnagiri, Maharashtra'
            : _locationController.text.trim(),
        "seller_id": userId,
        "seller_name": sellerName,
        "avg_rating": 5.0,
        "review_count": 1,
        "is_featured": true,
        "variants": [
          {
            "id": variantId,
            "product_id": prodId,
            "weight_value": 1.0,
            "weight_unit": _selectedUnit,
            "packaging_type": "Standard Pack",
            "mrp": (price * 1.25).roundToDouble(),
            "selling_price": price,
            "stock_quantity": qty.toInt(),
            "sku": "SKU-${prodId.substring(prodId.length - 4)}",
            "is_available": true,
          }
        ],
      };

      final repo = EcommerceRepository();
      final success = await repo.createProduct(productData);

      if (mounted) {
        if (success) {
          // Refresh global catalog
          context.read<EcommCatalogProvider>().fetchFilteredProducts();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 "${_titleController.text.trim()}" published to Marketplace!'),
              backgroundColor: const Color(0xFF0F9D58),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to publish product. Please check your connection.'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding stock: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F9D58),
        title: const Text(
          'Add Produce Stock',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF1B5E20)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D58).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seller Inventory Listing',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add your fresh agricultural products directly to the catalog',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product Image Upload Section
              _buildSectionLabel('PRODUCE PHOTO / IMAGE'),
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _uploadedImageUrl != null ? const Color(0xFF0F9D58) : Colors.grey[300]!,
                      width: _uploadedImageUrl != null ? 2 : 1,
                    ),
                  ),
                  child: _isUploadingImage
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF0F9D58)),
                              SizedBox(height: 10),
                              Text('Uploading photo to server...', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        )
                      : _selectedImageBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.photo_camera, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Change Photo', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F9D58).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0F9D58), size: 36),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap to choose produce image',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Supports JPG, PNG (High-resolution produce images)',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              _buildSectionLabel('PRODUCE NAME & TITLE'),
              TextFormField(
                controller: _titleController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter produce name' : null,
                decoration: _inputDecoration(
                  hint: 'e.g. Organic Ratnagiri Alphonso Mangoes',
                  icon: Icons.eco_outlined,
                ),
              ),
              const SizedBox(height: 18),

              // Category & Grade Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('CATEGORY'),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                          decoration: _inputDecoration(icon: Icons.category_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('QUALITY GRADE'),
                        DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          items: _grades
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGrade = v!),
                          decoration: _inputDecoration(icon: Icons.verified_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quantity & Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('AVAILABLE QUANTITY'),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter qty' : null,
                          decoration: _inputDecoration(hint: 'e.g. 500', icon: Icons.inventory_2_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('UNIT'),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          items: _units
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Unit Price & Organic Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('SELLING PRICE (₹ / unit)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter unit price' : null,
                          decoration: _inputDecoration(
                            hint: 'e.g. 180',
                            icon: Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('ORGANIC?'),
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Organic', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Switch(
                                value: _isOrganic,
                                activeColor: const Color(0xFF0F9D58),
                                onChanged: (v) => setState(() => _isOrganic = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Origin Location
              _buildSectionLabel('ORIGIN / FARM LOCATION'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(
                  hint: 'e.g. Ratnagiri, Maharashtra',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 18),

              // Description
              _buildSectionLabel('DESCRIPTION & HARVEST DETAILS'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  hint: 'Harvest freshness details, packaging specifications, nutritional highlights...',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                  label: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PUBLISH STOCK TO MARKETPLACE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0F9D58), size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F9D58), width: 2),
      ),
    );
  }
}
