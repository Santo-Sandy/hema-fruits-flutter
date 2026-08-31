import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productId;

  const ProductReviewsScreen({super.key, required this.productId});

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final List<Map<String, dynamic>> _customReviews = [];
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Super Fresh 🥦',
    'Fast Shipping ⚡',
    'Great Packaging 📦',
    'Value for Money 💰',
    'Juicy & Delicious 🤤',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openAddReviewSheet(BuildContext context) {
    _commentController.clear();
    _selectedRating = 5;
    _selectedTags.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Write a Customer Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 14),
                    const Text('Tap Stars to Rate:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (index) {
                        final starVal = index + 1;
                        final isSelected = starVal <= _selectedRating;
                        return IconButton(
                          icon: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color: isSelected ? Colors.amber : Colors.grey,
                            size: 32,
                          ),
                          onPressed: () {
                            setModalState(() {
                              _selectedRating = starVal;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    const Text('Select tags describing quality:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: AppColors.primarySoft,
                          checkmarkColor: AppColors.primary,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Write your comments here...',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (_commentController.text.trim().isNotEmpty) {
                            setState(() {
                              _customReviews.insert(0, {
                                'name': 'Santo Kumar (You)',
                                'date': 'Today',
                                'rating': _selectedRating.toDouble(),
                                'text': _commentController.text.trim(),
                                'tags': List<String>.from(_selectedTags),
                              });
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you! Review submitted successfully.'),
                                backgroundColor: Color(0xFF1E5E42),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please write comments to submit.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: const Text('SUBMIT REVIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final productList = catalog.products.where((p) => p.id == widget.productId).toList();
    final product = productList.isNotEmpty ? productList.first : catalog.products.first;

    // Local review mock lists matched to product rating
    final List<Map<String, dynamic>> defaultReviews = [
      {
        'name': 'Rahul Sharma',
        'date': '2 days ago',
        'rating': 5.0,
        'text': 'Absolutely pristine condition. Sourced fresh Shimla apples. Tastes sweet and juicy. Highly recommended.',
        'tags': ['Super Fresh 🥦', 'Great Packaging 📦'],
      },
      {
        'name': 'Priya Das',
        'date': '1 week ago',
        'rating': 4.5,
        'text': 'Very fresh Palak/Spinach leaves. Vacuum packed correctly. Sourced naturally and no pesticides smelled.',
        'tags': ['Super Fresh 🥦', 'Value for Money 💰'],
      },
      {
        'name': 'Animesh Roy',
        'date': '2 weeks ago',
        'rating': 4.0,
        'text': 'Perfect size jumbo cashew kernels. Crispy, roasted properly. Highly nutritious.',
        'tags': ['Great Packaging 📦', 'Juicy & Delicious 🤤'],
      }
    ];

    final allReviews = [..._customReviews, ...defaultReviews];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Ratings & Reviews',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Overview Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        product.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < product.avgRating.floor() ? Icons.star : Icons.star_half,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${product.reviewCount + _customReviews.length} Ratings',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _ratingBar(5, 0.85),
                        _ratingBar(4, 0.10),
                        _ratingBar(3, 0.03),
                        _ratingBar(2, 0.01),
                        _ratingBar(1, 0.01),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Review List Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Comments (${allReviews.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () => _openAddReviewSheet(context),
                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFF1E5E42)),
                  label: const Text('Write Review', style: TextStyle(color: Color(0xFF1E5E42), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Reviews List
            ...allReviews.map((rev) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rev['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          Text(rev['date'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${rev['rating']}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                ),
                                const Icon(Icons.star, size: 10, color: Colors.amber),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 4,
                            children: (rev['tags'] as List<String>).map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F3F4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tag, style: const TextStyle(fontSize: 9, color: Colors.black54)),
                                )).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rev['text'],
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _ratingBar(int star, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 10, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFE8EAED),
              color: Colors.amber,
              minHeight: 5,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
