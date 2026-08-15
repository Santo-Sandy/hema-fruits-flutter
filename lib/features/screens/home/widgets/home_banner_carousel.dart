import 'package:flutter/material.dart';

class HomeBannerCarousel extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final Function(String category) onCategoryTap;

  const HomeBannerCarousel({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> banners = [
      {
        'title': "Premium Cashews direct from Africa",
        'subtitle': "High Sea & Port deliveries",
        'btnText': "View Stocks",
        'gradient': [const Color(0xFF1E5E42), const Color(0xFF0F3A27)],
        'category': "RCN",
      },
      {
        'title': "Certified Export Grade Kernels",
        'subtitle': "W240, W320 & splits ready",
        'btnText': "View Offers",
        'gradient': [const Color(0xFFE65100), const Color(0xFFBF360C)],
        'category': "Kernel",
      },
      {
        'title': "Secure Purchase Requirements",
        'subtitle': "Get instant quotes from buyers",
        'btnText': "Sell Now",
        'gradient': [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
        'category': "Both",
      },
    ];

    return Container(
      height: 156,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final b = banners[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: b['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            b['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              final cat = b['category'] as String;
                              onCategoryTap(cat);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: b['gradient'][0] as Color,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              b['btnText'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Opacity(
                      opacity: 0.15,
                      child: Icon(
                        index == 2 ? Icons.trending_up_rounded : Icons.eco_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            right: 16,
            child: Row(
              children: List.generate(banners.length, (index) {
                final isSelected = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
