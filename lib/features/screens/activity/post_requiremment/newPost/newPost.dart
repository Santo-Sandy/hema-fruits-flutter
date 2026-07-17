import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/api_service.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/offline_queue_service.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'package:cashew_marketplace/shared/widgets/custom_input.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class NewPostScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? existingData;
  final String role;
  final String type;
  final String queryType;
  final String collectionName;

  const NewPostScreen({
    super.key,
    this.isEdit = false,
    this.existingData,
    required this.queryType,
    required this.role,
    required this.type,
    required this.collectionName,
  });

  @override
  State<NewPostScreen> createState() => _NewPostScreen();
}

class _NewPostScreen extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> uploadedImages = [];
  bool isUploadingImage = false;
  static const String _apiBase = "https://cerp.sgp1.digitaloceanspaces.com/";

  bool get hideGrade => widget.type.toUpperCase() == "RCN";
  bool get hideNutOutCrop => widget.type.toUpperCase() == "KERNEL";
  bool get hideCertificateHighSea => widget.role.toLowerCase() == "buyer";

  final nutCountController = TextEditingController();
  final outTurnController = TextEditingController();
  final requiredQtyController = TextEditingController();
  final minSupplyController = TextEditingController();
  final expectedPriceController = TextEditingController();
  final _pincodeController = TextEditingController();
  final cityController = TextEditingController();
  final descriptionController = TextEditingController();
  final moistureContentController = TextEditingController();

  DateTime? orderDate;
  DateTime? deliveryDate;
  DateTime? validBiddingDate;

  int? selectedCropYear = DateTime.now().year;
  String? selectedCountry;
  String? selectedOrigin = "India";
  String? selectedGrade = "W240";
  String? selectedCurrency = "INR";
  String selectedpriceper = "Kg";
  String priceunit = "Kg";
  String? selectedsale = "International";
  String? selectedsaleType = "CIF";
  String? shipmentsaleTypeError;
  String? saleError;
  String? saleTypeError;
  String unit = 'Kg';
  int initial = 0;

  bool certificate = false;
  bool isshipment = true;
  bool highSea = false;
  bool allowLowerBids = false;
  bool editqty = true;

  bool isLoading = false;
  int currentYear = DateTime.now().year;
  int confirmedkg = 0;

  List<String> countries = ["India", "Vietnam", "Brazil"];
  List<String> origins = [];
  List<String> grades = [
    "W180",
    "W240",
    "W320",
    "W450",
    "W500",
    "Broken BB",
    "Broken LP",
  ];
  List<String> sale = ["Domestic", "International", "High Sea"];
  List<String> shipmentsaleTypes = ["CIF", "FOB"];
  List<String> saleTypes = ["Inclusive of VAT/GST", "Exclusive of VAT/GST"];
  List<String> currencies = ["INR", "USD", "EUR"];
  List<String> Priceper = ["Kg", "MT"];
  List<int> get cropYears => [currentYear - 1, currentYear, currentYear + 1];
  List<dynamic> biddings = [];

  static const int maxDigits = 8;
  String numberError = '';
  String nutCountError = '';
  String outTurnError = '';
  String moistureError = '';

  // --- NEW: error state for dropdowns and date pickers ---
  String? originError;
  String? gradeError;
  String? cropYearError;
  String? currencyError;
  String? priceperError;
  String? orderDateError;
  String? deliveryDateError;
  String? validBiddingDateError;
  Map<String, dynamic> data = {};
  Map<String, dynamic> userdata = {};
  ConnectivityResult result = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ContextManager().saveCurrentPage('Newpost', context);
      if (mounted) getPosts();
      if (mounted && widget.isEdit) fetchEditData();
    });
  }

  @override
  void dispose() {
    nutCountController.dispose();
    outTurnController.dispose();
    requiredQtyController.dispose();
    minSupplyController.dispose();
    expectedPriceController.dispose();
    cityController.dispose();
    descriptionController.dispose();
    moistureContentController.dispose();
    super.dispose();
  }

  Future<void> fetchEditData() async {
    if (!widget.isEdit || widget.existingData == null) return;

    try {
      if (mounted) setState(() => isLoading = true);

      final service = PostService();
      final response = await service.getById(
        collectionName: "post",
        id: widget.existingData!["_id"],
      );
      if (!mounted) return;

      final responseData = response["data"];

      if (responseData is List && responseData.isNotEmpty) {
        if (mounted) loadEditDataFromApi(responseData[0]);
      } else if (responseData is Map<String, dynamic>) {
        if (mounted) loadEditDataFromApi(responseData);
      }
      if (responseData[0]!['confirmedKg'] != null) {
        setState(() {
          confirmedkg = responseData[0]['confirmedKg'];
          editqty = false;
        });
      }
      userdata = await SecureStorageService.getUserData();
    } catch (e) {
      if (mounted) showError("Failed to load data");
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> getPosts() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    final provider = context.read<EditPostProvider>();
    await provider.fetch(endpoint: "entities/filter/origin", filterPayload: {});
    if (!mounted) return;
    final data = provider.post;
    if (data.isNotEmpty && mounted) {
      setState(() {
        result = results;
        origins = data.map((e) => e['name'].toString()).toList();
        origins.sort();
        selectedOrigin = origins.isNotEmpty ? origins[0] : null;
      });
    }
  }

  String formatNumberWithCommas(String digits) {
    if (digits.isEmpty) return '';
    final reversed = digits.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.skip(i).take(3).join());
    }
    return chunks.join(',').split('').reversed.join();
  }

  String removeCommas(String value) => value.replaceAll(',', '');

  void loadEditDataFromApi(Map<String, dynamic> datas) {
    data = datas;
    if (!mounted) return;
    if (widget.role == "buyer") {
      selectedCropYear = int.tryParse(data["yearOfCrop"]?.toString() ?? "");
      final country = data["country"]?.toString() ?? "";
      selectedCountry = countries.contains(country) ? country : null;
      selectedOrigin = data["origin"];
      selectedGrade = data["grade"];
      biddings = data['biddings'] ?? [];
      final currency = data["currency"]?.toString().toUpperCase() ?? "";
      selectedCurrency = currencies.contains(currency) ? currency : null;
      selectedsale = data['shipmenttype']?.toString() ?? "";
      isshipment = data['shipmenttype']?.toString() == 'International';
      selectedsaleType = data['shippingmethod']?.toString() ?? "";
      selectedpriceper = data['priceunit']?.toString() ?? "";
      priceunit = data['priceunit']?.toString() ?? "";
      initial = int.tryParse(data['initialprice']?.toString() ?? "0") ?? 0;
      unit = data['unit']?.toString() ?? "";
      nutCountController.text = data["nutCount"]?.toString() ?? "";
      _pincodeController.text = data["pincode"]?.toString() ?? "";
      outTurnController.text = data["outTurn"]?.toString() ?? "";
      final availableQty =
          int.tryParse(data["requiredqty"]?.toString() ?? "0") ?? 0;

      final minimumQty =
          int.tryParse(data["minimumqty"]?.toString() ?? "0") ?? 0;

      final qty = unit == "MT"
          ? ((availableQty / 1000).round()).toString()
          : availableQty.toString();

      final minSupplyQty = unit == "MT"
          ? ((minimumQty / 1000).round()).toString()
          : minimumQty.toString();
      requiredQtyController.text = formatNumberWithCommas(qty);
      minSupplyController.text = formatNumberWithCommas(minSupplyQty);
      expectedPriceController.text = formatNumberWithCommas(
        data["expectedprice"]?.toString() ?? "",
      );
      cityController.text = data["city"] ?? "";
      descriptionController.text = data["description"] ?? "";
      moistureContentController.text =
          data["moistureContent"]?.toString() ?? "";
      allowLowerBids = data["lowerbit"] ?? false;
      if (data["orderDate"] != null) {
        orderDate = DateTime.parse(data["orderDate"]).toLocal();
      }
      if (data["deliverydate"] != null) {
        deliveryDate = DateTime.parse(data["deliverydate"]).toLocal();
      }
    } else {
      selectedCropYear = int.tryParse(data["yearofcrop"]?.toString() ?? "");
      final country = data["country"]?.toString() ?? "";
      selectedCountry = countries.contains(country) ? country : null;
      selectedOrigin = data["origin"];
      selectedGrade = data["grade"];
      biddings = data['biddings'] ?? [];
      _pincodeController.text = data["pincode"]?.toString() ?? "";
      final currency = data["currency"]?.toString().toUpperCase() ?? "";
      selectedCurrency = currencies.contains(currency) ? currency : null;
      nutCountController.text = data["netcount"]?.toString() ?? "";
      outTurnController.text = data["outturn"]?.toString() ?? "";
      initial = int.tryParse(data['initialprice']?.toString() ?? "0") ?? 0;
      selectedsale = data['shipmenttype']?.toString() ?? "";
      unit = data['unit']?.toString() ?? "";
      isshipment = data['shipmenttype']?.toString() == 'International';
      selectedsaleType = data['shippingmethod']?.toString() ?? "";
      selectedpriceper = data['priceunit']?.toString() ?? "";
      priceunit = data['priceunit']?.toString() ?? "";
      final availableQty =
          int.tryParse(data["availableqty"]?.toString() ?? "0") ?? 0;

      final minimumQty =
          int.tryParse(data["minimumqty"]?.toString() ?? "0") ?? 0;

      final qty = unit == "MT"
          ? ((availableQty / 1000).round()).toString()
          : availableQty.toString();

      final minSupplyQty = unit == "MT"
          ? ((minimumQty / 1000).round()).toString()
          : minimumQty.toString();
      requiredQtyController.text = formatNumberWithCommas(qty);
      minSupplyController.text = formatNumberWithCommas(minSupplyQty);
      expectedPriceController.text = formatNumberWithCommas(
        data["sellingprice"]?.toString() ?? "",
      );
      cityController.text = data["location"] ?? "";
      descriptionController.text = data["description"] ?? "";
      moistureContentController.text =
          data["moistureContent"]?.toString() ?? "";
      allowLowerBids = data["negotiateprice"] ?? false;
      certificate = data["rba"] ?? false;
      highSea = data["high"] ?? false;
      if (data["fromdate"] != null) {
        orderDate = DateTime.parse(data["fromdate"]).toLocal();
      }
      if (data["expiredate"] != null) {
        deliveryDate = DateTime.parse(data["expiredate"]).toLocal();
      }

      final imgs = data["images"];
      if (imgs is List) {
        uploadedImages = imgs
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
  }

  void handleNumericInput(TextEditingController controller, String fieldName) {
    final value = controller.text;
    final digitsOnly = removeCommas(value);

    if (digitsOnly.isEmpty) {
      setState(() {
        numberError = '';
        if (fieldName == 'nutCount') nutCountError = '';
        if (fieldName == 'outTurn') outTurnError = '';
        if (fieldName == 'moistureContent') moistureError = '';
      });
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      controller.text = value.substring(0, value.length - 1);
      return;
    }

    if (digitsOnly.startsWith('0')) {
      controller.text = value.substring(0, value.length - 1);
      return;
    }

    final numericValue = int.tryParse(digitsOnly) ?? 0;

    if (fieldName == 'moistureContent') {
      if (digitsOnly.length > 2) {
        controller.text = value.substring(0, value.length - 1);
        return;
      }
      setState(() {
        moistureError = numericValue > 20
            ? Translate.t("errors.moisture_less_than")
            : '';
      });
      return;
    }

    if (fieldName == 'nutCount') {
      if (digitsOnly.length > 3) {
        controller.text = value.substring(0, value.length - 1);
        return;
      }
      setState(() {
        nutCountError = (numericValue < 140 || numericValue > 260)
            ? Translate.t("errors.nut_count_range")
            : '';
      });
      return;
    }

    if (fieldName == 'outTurn') {
      if (digitsOnly.length > 2) {
        controller.text = value.substring(0, value.length - 1);
        return;
      }
      setState(() {
        outTurnError = (numericValue < 22 || numericValue > 60)
            ? Translate.t("errors.outturn_range")
            : '';
      });
      return;
    }

    if (digitsOnly.length > maxDigits) {
      controller.text = value.substring(0, value.length - 1);
      return;
    }

    final quantityValue =
        int.tryParse(removeCommas(requiredQtyController.text)) ?? 0;

    final minSupplyValue =
        int.tryParse(removeCommas(minSupplyController.text)) ?? 0;

    if (quantityValue > 0 &&
        minSupplyValue > 0 &&
        minSupplyValue > quantityValue) {
      setState(() {
        numberError = 'Minimum Supply Quantity cannot be greater than Quantity';
      });
    } else {
      setState(() {
        numberError = '';
      });
    }

    final formattedValue = formatNumberWithCommas(digitsOnly);
    controller.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: formattedValue.length.clamp(0, formattedValue.length),
      ),
    );
  }

  String? validateNutCount(String? value) {
    if (hideNutOutCrop) return null;
    if (value == null || value.isEmpty) return Translate.t("errors.required");
    if (nutCountError.isNotEmpty) return nutCountError;
    return null;
  }

  String? validateOutTurn(String? value) {
    if (hideNutOutCrop) return null;
    if (value == null || value.isEmpty) return Translate.t("errors.required");
    if (outTurnError.isNotEmpty) return outTurnError;
    return null;
  }

  String? validateMoistureContent(String? value) {
    if (value == null || value.isEmpty) return Translate.t("errors.required");
    if (moistureError.isNotEmpty) return moistureError;
    return null;
  }

  // --- NEW: _validateAll triggers all validations and returns true if form is valid ---
  bool _validateAll() {
    // Trigger Flutter's built-in form validators (text fields, etc.)
    final formValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      originError = selectedOrigin == null ? 'Required' : null;
      gradeError = (!hideGrade && selectedGrade == null) ? 'Required' : null;
      cropYearError = (!hideNutOutCrop && selectedCropYear == null)
          ? 'Required'
          : null;
      currencyError = selectedCurrency == null ? 'Required' : null;
      orderDateError = orderDate == null ? 'Required' : null;
      deliveryDateError = deliveryDate == null ? 'Required' : null;
    });

    final dropdownsValid =
        originError == null &&
        gradeError == null &&
        cropYearError == null &&
        currencyError == null &&
        orderDateError == null &&
        deliveryDateError == null;

    final inlineErrorsValid =
        numberError.isEmpty && nutCountError.isEmpty && outTurnError.isEmpty;

    return formValid && dropdownsValid && inlineErrorsValid;
  }

  Future<void> pickOrderDate() async {
    final initialDate = selectedCropYear == currentYear + 1
        ? DateTime(currentYear + 1, 1, 1)
        : (orderDate ?? DateTime.now());
    final firstDate = selectedCropYear == currentYear + 1
        ? DateTime(currentYear + 1, 1, 1)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        orderDate = picked;
        // final order = picked.toUtc();
        // final od = order.toLocal();
        deliveryDate = null;
        orderDateError = null; // clear error on pick
      });
    }
  }

  Future<void> pickDeliveryDate() async {
    if (orderDate == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: deliveryDate ?? orderDate!,
      firstDate: orderDate!,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        deliveryDate = picked;
        deliveryDateError = null; // clear error on pick
      });
    }
  }

  // Future<void> pickValidBiddingDate() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: validBiddingDate,
  //     firstDate: DateTime.now(),
  //     lastDate: DateTime(2100),
  //   );
  //   if (picked != null) {
  //     final time = await showTimePicker(
  //       context: context,
  //       initialTime: TimeOfDay.now(),
  //     );
  //     if (time != null) {
  //       setState(() {
  //         validBiddingDate = picked.add(
  //           Duration(hours: time.hour, minutes: time.minute),
  //         );
  //         validBiddingDateError = null; // clear error on pick
  //       });
  //     }
  //   }
  // }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    if (mounted) setState(() => isUploadingImage = true);

    for (final pickedFile in picked) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;

        final dio = ApiService.instance.dio;
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
          'folders': 'marketplace/stocks',
        });

        final response = await dio.post(
          'file/marketplace/stocks',
          data: formData,
        );
        final resData = response.data;

        if (resData != null && resData["status"] == 200) {
          final fileData = resData["data"][0];
          if (mounted) {
            setState(() {
              uploadedImages.add(Map<String, dynamic>.from(fileData));
            });
          }
        }
      } catch (e) {
        debugPrint('Image upload failed: $e');
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          } catch (_) {}
        }
      }
    }

    if (mounted) setState(() => isUploadingImage = false);
  }

  Future<void> showUnitSelector(BuildContext context, String type) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Unit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                // leading: const Icon(Icons.scale),
                title: const Text('Kilogram (Kg)'),
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    if (type == "unit") {
                      unit = "Kg";
                    } else {
                      selectedpriceper = "Kg";
                    }
                  });
                },
              ),

              const Divider(height: 1),

              ListTile(
                // leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Metric Ton (MT)'),
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    if (type == "unit") {
                      unit = "MT";
                    } else {
                      selectedpriceper = "MT";
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showCurrencySelector(BuildContext context, String type) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Currency',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.separated(
              itemCount: currencies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final currency = currencies[index];

                return Column(
                  children: [
                    ListTile(
                      title: Text(currency),
                      onTap: () {
                        Navigator.pop(context);

                        setState(() {
                          selectedCurrency = currency;
                        });
                      },
                    ),
                    IntrinsicWidth(
                      child: Divider(
                        height: 1,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> removeImage(int index, Map<String, dynamic> img) async {
    if (!mounted || index < 0 || index >= uploadedImages.length) return;
    setState(() => uploadedImages.removeAt(index));
    try {
      final dio = ApiService.instance.dio;
      await dio.delete('file/${img['_id']}');
    } catch (e) {
      debugPrint('Delete image failed: $e');
    }
  }

  // --- UPDATED: uses _validateAll() instead of isFormValid ---
  Future<void> saveRequirement() async {
    if (!_validateAll()) return;

    setState(() => isLoading = true);

    try {
      final user = await SecureStorageService.getUserData();
      if (!mounted) return;

      // final priced = widget.isEdit
      //     ? priceunit != selectedpriceper
      //           ? selectedpriceper == 'MT'
      //                 ? int.parse(removeCommas(expectedPriceController.text)) *
      //                       1000
      //                 : int.parse(removeCommas(expectedPriceController.text)) /
      //                       1000
      //           : int.parse(removeCommas(expectedPriceController.text))
      //     : int.parse(removeCommas(expectedPriceController.text));

      final bidding = {
        'id': user['_id'],
        'name': user['name'] ?? "Post owner",
        'profile': user['profilePicture'],
        'date': DateTime.now().toUtc().toIso8601String(),
        'price': int.parse(removeCommas(expectedPriceController.text)),
      };
      if (widget.isEdit && priceunit != selectedpriceper) {
        if (selectedpriceper == 'MT') {
          final bid = biddings.map((bid) {
            return {...bid, 'price': (bid['price'] as num) * 1000};
          }).toList();
          biddings = bid;
        }
        if (selectedpriceper == 'Kg') {
          final bid = biddings.map((bid) {
            return {...bid, 'price': ((bid['price'] as num) / 1000).round()};
          }).toList();
          biddings = bid;
        }
      }
      biddings.add(bidding);

      final userId = user["_id"];
      Map<String, dynamic> payload;
      if (widget.role == "buyer") {
        payload = {
          "buyerId": userId,
          "userid": userId,
          "nutCount": hideNutOutCrop ? "" : nutCountController.text,
          "type": widget.type,
          "status": "Active",
          "requiredqty": unit == 'MT'
              ? (int.parse(removeCommas(requiredQtyController.text)) * 1000)
              : int.parse(removeCommas(requiredQtyController.text)),
          "orderDate": !widget.isEdit
              ? orderDate
                    ?.add(const Duration(hours: 23, minutes: 59, seconds: 59))
                    .toUtc()
                    .toIso8601String()
              : orderDate!.toUtc().toIso8601String(),
          "country": selectedCountry ?? "",
          "outTurn": hideNutOutCrop ? "" : outTurnController.text,
          "pincode": _pincodeController.text ?? " ",
          "origin": selectedOrigin,
          "biddings": biddings,
          "minimumqty": unit == 'MT'
              ? (int.parse(removeCommas(minSupplyController.text)) * 1000)
              : int.parse(removeCommas(minSupplyController.text)),
          "location": cityController.text,
          "shipmenttype": selectedsale,
          "priceunit": selectedpriceper,
          "unit": unit,
          "priceincludegst": selectedsaleType == "Included GST",
          "shippingmethod": selectedsaleType,
          "yearOfCrop": hideNutOutCrop ? "" : selectedCropYear.toString(),
          "description": descriptionController.text,
          "grade": hideGrade ? "RCN" : (selectedGrade ?? ""),
          "expectedprice": int.parse(
            removeCommas(expectedPriceController.text),
          ),
          "deliverydate": !widget.isEdit
              ? deliveryDate
                    ?.add(const Duration(hours: 23, minutes: 59, seconds: 59))
                    .toUtc()
                    .toIso8601String()
              : deliveryDate!.toUtc().toIso8601String(),
          "city": cityController.text,
          "lowerbit": allowLowerBids,
          "isDeleted": false,
          "created_by": userId,
          "currency": selectedCurrency,
          // "moistureContent": hideGrade
          //     ? 0
          //     : int.parse(moistureContentController.text),
        };
        if (hideGrade) {
          payload["moistureContent"] = int.parse(
            moistureContentController.text,
          );
        }
      } else {
        payload = {
          "origin": selectedOrigin,
          "type": widget.type,
          "grade": hideGrade ? "RCN" : (selectedGrade ?? ""),
          "outturn": hideNutOutCrop ? "" : outTurnController.text,
          "yearofcrop": hideNutOutCrop ? "" : selectedCropYear.toString(),
          "rba": certificate,
          "netcount": hideNutOutCrop ? "" : nutCountController.text,
          "minimumqty": unit == 'MT'
              ? (int.parse(removeCommas(minSupplyController.text)) * 1000)
              : int.parse(removeCommas(minSupplyController.text)),
          "sellingprice": int.parse(removeCommas(expectedPriceController.text)),
          "availableqty": unit == 'MT'
              ? (int.parse(removeCommas(requiredQtyController.text)) * 1000)
              : int.parse(removeCommas(requiredQtyController.text)),
          "pincode": _pincodeController.text ?? " ",
          "location": cityController.text,
          "biddings": biddings,
          "priceunit": selectedpriceper,
          "unit": unit,
          "priceincludegst": selectedsaleType == "Included GST",
          "country": selectedCountry ?? "",
          "shipmenttype": selectedsale,
          "shippingmethod": selectedsaleType,
          "fromdate": !widget.isEdit
              ? orderDate
                    ?.add(const Duration(hours: 23, minutes: 59, seconds: 59))
                    .toUtc()
                    .toIso8601String()
              : orderDate!.toUtc().toIso8601String(),
          "expiredate": !widget.isEdit
              ? deliveryDate
                    ?.add(const Duration(hours: 23, minutes: 59, seconds: 59))
                    .toUtc()
                    .toIso8601String()
              : deliveryDate!.toUtc().toIso8601String(),
          "high": highSea,
          "negotiateprice": allowLowerBids,
          "description": descriptionController.text,
          "images": uploadedImages,
          "status": "Active",
          "userid": userId,
          "created_by": userId,
          "isDeleted": false,
          "currency": selectedCurrency,
        };
        if (hideGrade) {
          payload["moistureContent"] = int.parse(
            moistureContentController.text,
          );
        }
      }
      // if (widget.isEdit) {
      //   if (widget.role == 'buyer') {
      //     payload["initialprice"] = data["expectedprice"];
      //   } else {
      //     payload["initialprice"] = data["sellingprice"];
      //   }
      // }
      if (!widget.isEdit) {
        payload["created_on"] = DateTime.now().toUtc().toIso8601String();
        payload["initialprice"] = int.parse(
          removeCommas(expectedPriceController.text),
        );
      }
      if (widget.isEdit) {
        final priced = priceunit != selectedpriceper
            ? selectedpriceper == 'MT'
                  ? (initial * 1000).round()
                  : (initial / 1000).round()
            : initial;
        payload["initialprice"] = priced;
      }
      // if (allowLowerBids) {
      //   payload["validBiddingDate"] = validBiddingDate!
      //       .toUtc()
      //       .toIso8601String();
      // }
      final service = PostService();

      final isOffline = await OfflineQueueService.instance.isOnline() == false;
      final requestId =
          '${DateTime.now().microsecondsSinceEpoch}_${widget.collectionName.hashCode}';

      if (widget.isEdit) {
        final res = await service.dynamicUpdate(
          collectionName: widget.collectionName,
          id: widget.existingData!["_id"],
          data: payload,
          requestId: requestId,
        );
        context.pop();
      } else {
        final res = await service.dynamicPost(
          collectionName: widget.collectionName,
          queryType: widget.queryType,
          data: payload,
          requestId: requestId,
        );

        if (res.error != null) {
          showError(res.error!);
        }

        if (isOffline ||
            res.data is Map<String, dynamic> && res.data['queued'] == true) {
          final localPost = {
            ...payload,
            '_id': requestId,
            'offlineQueueId': requestId,
            'isOffline': true,
            'post_type': widget.role == 'buyer' ? 'requirements' : 'stocks',
            'queryType': widget.queryType,
          };

          if (mounted) {
            try {
              final myPostProvider = context.read<MyPostProvider>();
              await myPostProvider.insertLocalPost(localPost);
            } catch (_) {}
          }
        }
        context.push(RoutePath.myActivity);
      }
    } catch (e) {
      if (mounted) showError("Something went wrong");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Widget _buildImageUploadSection(ConnectivityResult result) {
    if (hideCertificateHighSea) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Translate.t("post.images")),
        const SizedBox(height: 16),
        result == ConnectivityResult.none
            ? GestureDetector(
                onTap: () => showError("No internet connection"),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withAlpha(90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .3),
                      width: 1.5,
                    ),
                  ),
                  child: isUploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.primary.withValues(alpha: .5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload images',
                              style: AppTextThemes.getLightTextTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondaryLight
                                        .withAlpha(90),
                                  ),
                            ),
                            Text(
                              'JPG, PNG supported',
                              style: AppTextThemes.getLightTextTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondaryLight
                                        .withAlpha(90),
                                  ),
                            ),
                          ],
                        ),
                ),
              )
            : GestureDetector(
                onTap: isUploadingImage ? null : pickAndUploadImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .3),
                      width: 1.5,
                    ),
                  ),
                  child: isUploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.primary.withValues(alpha: .5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload images',
                              style: AppTextThemes.getLightTextTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                            ),
                            Text(
                              'JPG, PNG supported',
                              style: AppTextThemes.getLightTextTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),
        if (uploadedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: uploadedImages.length,
            itemBuilder: (context, index) {
              final img = uploadedImages[index];
              final url = '$_apiBase${img['storage_name']}';
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.borderLight,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => removeImage(index, img),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextThemes.getLightTextTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: accepts optional errorText, shows red border + message below ---
  Widget _buildDatePickerTile({
    required String title,
    required VoidCallback? onTap,
    bool isDisabled = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDisabled ? AppColors.cream : Colors.white,
              border: Border.all(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.borderLight,
                width: errorText != null ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                    color: isDisabled
                        ? AppColors.disabled
                        : (errorText != null
                              ? AppColors.error
                              : AppColors.textPrimary),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: isDisabled
                      ? AppColors.disabled
                      : (errorText != null
                            ? AppColors.error
                            : AppColors.primary),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SwapUserProvider>().swapedUser;
    final effectiveRole = widget.role.isNotEmpty ? widget.role : role;
    final ismobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          onPressed: () {
            if (!mounted) return;
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.push(RoutePath.myActivity);
              }
            } catch (_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          '${widget.type} - ${widget.role == 'buyer' ? "Purchase" : "Sale"}',
          style: AppTextThemes.getLightTextTheme.titleLarge?.copyWith(
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: isLoading && widget.isEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // ─────────────────────────────────────────
                    // MOBILE LAYOUT
                    // ─────────────────────────────────────────
                    if (ismobile) ...[
                      _buildSectionHeader(
                        Translate.t("post.basic_information"),
                      ),
                      const SizedBox(height: 12),

                      if (!hideNutOutCrop)
                        CustomDropdownFormField<int>(
                          isEnabled: editqty,
                          value: selectedCropYear ?? DateTime.now().year,
                          items: cropYears,
                          prefixIcon: Icons.calendar_month,
                          labels: cropYears.map((y) => '$y').toList(),
                          label: Translate.t("post.crop_year"),
                          onChanged: (v) => setState(() {
                            selectedCropYear = v;
                            orderDate = null;
                            deliveryDate = null;
                            cropYearError = null; // clear on change
                          }),
                          validator: (v) =>
                              v == null ? Translate.t("common.required") : null,
                          isRequired: !hideNutOutCrop,
                        ),
                      if (!hideGrade)
                        CustomDropdownFormField<String>(
                          isEnabled: editqty,
                          value: selectedGrade ?? "W240",
                          items: grades,
                          labels: grades,
                          label: Translate.t("post.grade"),
                          onChanged: (v) => setState(() {
                            selectedGrade = v;
                            gradeError = null; // clear on change
                          }),
                          validator: (v) =>
                              !hideGrade && v == null ? "Required" : null,
                          isRequired: !hideGrade,
                          prefixIcon: Icons.category,
                        ),

                      const SizedBox(height: 16),
                      CustomDropdownFormField<String>(
                        value: selectedOrigin ?? userdata['country'],
                        items: origins,
                        labels: origins,
                        label: Translate.t("post.origin"),
                        onChanged: (v) => setState(() {
                          selectedOrigin = v;
                          originError = null; // clear on change
                        }),
                        prefixIcon: Icons.language,
                        validator: (v) => v == null ? "Required" : null,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownFormField<String>(
                        value: selectedsale,
                        items: sale,
                        labels: sale,
                        label: Translate.t("post.shipment_type"),
                        onChanged: (v) => setState(() {
                          selectedsale = v;
                          if (v == "International") {
                            setState(() {
                              highSea = false;
                              isshipment = true;
                            });
                          }
                          if (v == "High Sea") {
                            setState(() {
                              highSea = true;
                              isshipment = true;
                            });
                          } else {
                            setState(() {
                              highSea = false;
                              isshipment = false;
                            });
                          }
                          saleError = null; // clear on change
                        }),
                        // prefixIcon: Icons.local_shipping,
                        validator: (v) => v == null ? "Required" : null,
                        isRequired: true,
                      ),

                      if (!hideNutOutCrop) ...[
                        // const SizedBox(height: 12),
                        _buildSectionHeader(
                          Translate.t("post.quality_specifications"),
                        ),
                        // const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: CustomCheckbox(
                              value: certificate,
                              onChanged: (v) =>
                                  setState(() => certificate = v ?? false),
                              label: Translate.t("post.rbs_certificate"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: outTurnController,
                          label: Translate.t("post.out_turn"),
                          hintText: "22 - 60",
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              handleNumericInput(outTurnController, 'outTurn'),
                          validator: validateOutTurn,
                          errorText: outTurnError.isNotEmpty
                              ? outTurnError
                              : null,
                        ),
                        // const SizedBox(height: 4),
                        CustomTextFormField(
                          controller: nutCountController,
                          label: Translate.t("post.nut_count"),
                          hintText: "140 - 260",
                          keyboardType: TextInputType.number,
                          onChanged: (_) => handleNumericInput(
                            nutCountController,
                            'nutCount',
                          ),
                          validator: validateNutCount,
                          errorText: nutCountError.isNotEmpty
                              ? nutCountError
                              : null,
                        ),
                        // const SizedBox(height: 8),

                        // const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: moistureContentController,
                          label: Translate.t("post.moisture_content"),
                          hintText: Translate.t("post.moisture_hint"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => handleNumericInput(
                            moistureContentController,
                            'moistureContent',
                          ),
                          validator: validateMoistureContent,
                          errorText: moistureError.isNotEmpty
                              ? moistureError
                              : null,
                        ),
                      ],
                      // const SizedBox(height: 8),
                      _buildSectionHeader(Translate.t("post.quantity_pricing")),
                      const SizedBox(height: 8),

                      CustomTextFormFieldright(
                        controller: requiredQtyController,
                        label: widget.role == "buyer"
                            ? Translate.t("post.required_quantity")
                            : Translate.t("post.available_quantity"),
                        hintText: Translate.t("post.enter_quantity"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          MinValueInputFormatter(confirmedkg),
                          MaxValueInputFormatter(99999999),
                        ],
                        onChanged: (_) => handleNumericInput(
                          requiredQtyController,
                          'quantity',
                        ),
                        onVerifyPressed: () {
                          // showUnitSelector(context, "unit");
                        },
                        suffixIcon: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            setState(() {
                              unit = value;
                            });
                          },
                          itemBuilder: (context) {
                            return ['Kg', 'MT']
                                .map(
                                  (currency) => PopupMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  ),
                                )
                                .toList();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  unit,
                                  style: AppTextThemes
                                      .getLightTextTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        errorText: numberError.isNotEmpty ? numberError : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return Translate.t("post.value_required");
                          }
                          final intValue = int.tryParse(removeCommas(value));
                          if (intValue == null) {
                            return Translate.t("post.enter_valid_number");
                          }
                          if (intValue < confirmedkg) {
                            return Translate.t(
                              "post.minimum_value",
                            ).replaceAll("{value}", "$confirmedkg");
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),
                      CustomTextFormFieldright(
                        controller: minSupplyController,
                        label: widget.role == "buyer"
                            ? Translate.t("post.minimum_supply_quantity")
                            : Translate.t("post.minimum_order_quantity"),
                        hintText: Translate.t("post.minimum_quantity"),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => handleNumericInput(
                          minSupplyController,
                          'minSupplyQuantity',
                        ),
                        // onVerifyPressed: () {
                        //   setState(() {
                        //     unit = unit == 'Kg' ? 'MT' : "Kg";
                        //   });
                        // },
                        suffixIcon: IntrinsicWidth(
                          child: Row(
                            children: [
                              // Icon(Icons.swap_vert, color: AppColors.primary),
                              Text(
                                unit,
                                style: AppTextThemes
                                    .getLightTextTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? Translate.t("post.required")
                            : null,

                        errorText: numberError.isNotEmpty ? numberError : null,
                      ),
                      const SizedBox(height: 8),
                      isshipment
                          ? CustomDropdownFormField<String>(
                              value: selectedsaleType,
                              items: shipmentsaleTypes,
                              labels: shipmentsaleTypes,
                              label: Translate.t("post.shipment_basis"),
                              onChanged: (v) => setState(() {
                                selectedsaleType = v;
                                shipmentsaleTypeError = null; // clear on change
                              }),
                              // prefixIcon: Icons.local_shipping,
                              validator: (v) => v == null ? "Required" : null,
                              isRequired: true,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: CustomCheckbox(
                                    label: "Inclusive of VAT/GST",
                                    value:
                                        selectedsaleType ==
                                            "Inclusive of VAT/GST"
                                        ? true
                                        : false,
                                    onChanged: (v) => setState(() {
                                      selectedsaleType = v == true
                                          ? "Inclusive of VAT/GST"
                                          : "Exclusive of VAT/GST";
                                      shipmentsaleTypeError =
                                          null; // clear on change
                                    }),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextFormFieldright(
                              controller: expectedPriceController,
                              label: widget.role == "buyer"
                                  ? Translate.t(
                                      "post.expected_selling_price_per_kg",
                                    )
                                  : Translate.t("post.selling_price_per_kg"),
                              hintText: "0.00",
                              onVerifyPressed: () {
                                // showUnitSelector(context, "selectedpriceper");
                                // setState(() {
                                //   selectedpriceper = selectedpriceper == 'Kg'
                                //       ? 'MT'
                                //       : "Kg";
                                // });
                              },
                              onprefixPressed: () {
                                showCurrencySelector(
                                  context,
                                  "selected currency",
                                );
                                // setState(() {
                                //   selectedpriceper = selectedpriceper == 'Kg'
                                //       ? 'MT'
                                //       : "Kg";
                                // });
                              },
                              // prefixIcon: IntrinsicWidth(
                              //   child: CustomDropdownFormField<String>(
                              //     decoration: InputDecoration(
                              //       // contentPadding: EdgeInsets.symmetric(
                              //       //   horizontal: 8,
                              //       //   vertical: 0,
                              //       // ),
                              //       suffixIcon: const Icon(
                              //         Icons.arrow_drop_down,
                              //         size: 20,
                              //       ),
                              //       border: OutlineInputBorder(
                              //         borderSide: BorderSide(
                              //           color: Colors.transparent,
                              //         ),
                              //       ),
                              //     ),
                              //     borderColor: Colors.transparent,
                              //     value: selectedCurrency,
                              //     items: currencies,
                              //     labels: currencies,
                              //     // label: Translate.t("post.currency"),
                              //     labelStyle: const TextStyle(
                              //       overflow: TextOverflow.ellipsis,
                              //     ),
                              //     onChanged: (v) => setState(() {
                              //       selectedCurrency = v;
                              //       currencyError = null; // clear on change
                              //     }),
                              //     validator: (v) =>
                              //         v == null ? 'Required' : null,
                              //     isRequired: true,
                              //   ),
                              // ),
                              prefixIcon: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  setState(() {
                                    selectedCurrency = value;
                                  });
                                },
                                itemBuilder: (context) {
                                  return currencies
                                      .map(
                                        (currency) => PopupMenuItem<String>(
                                          value: currency,
                                          child: Text(currency),
                                        ),
                                      )
                                      .toList();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedCurrency ?? "USD",
                                        style: AppTextThemes
                                            .getLightTextTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              suffixIcon: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  setState(() {
                                    selectedpriceper = value;
                                  });
                                },
                                itemBuilder: (context) {
                                  return ['Kg', 'MT']
                                      .map(
                                        (currency) => PopupMenuItem<String>(
                                          value: currency,
                                          child: Text(currency),
                                        ),
                                      )
                                      .toList();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedpriceper,
                                        style: AppTextThemes
                                            .getLightTextTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => handleNumericInput(
                                expectedPriceController,
                                'expectedPrice',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Required" : null,
                            ),
                          ),
                          // const SizedBox(width: 5),
                          // Expanded(
                          //   flex: 2,
                          //   child: Column(
                          //     children: [
                          //       CustomDropdownFormField<String>(
                          //         value: selectedpriceper,
                          //         items: Priceper,
                          //         labels: Priceper,
                          //         label: Translate.t("Kg/MT *"),
                          //         labelStyle: const TextStyle(
                          //           overflow: TextOverflow.ellipsis,
                          //         ),
                          //         onChanged: (v) => setState(() {
                          //           selectedpriceper = v;
                          //           priceperError = null; // clear on change
                          //         }),
                          //         validator: (v) =>
                          //             v == null ? 'Required' : null,
                          //         isRequired: true,
                          //       ),
                          //       SizedBox(height: 20),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _buildSectionHeader(
                        widget.role == "buyer"
                            ? Translate.t("post.location_supply")
                            : Translate.t("post.location_availability"),
                      ),
                      const SizedBox(height: 8),

                      CustomTextFormField(
                        controller: cityController,
                        label: Translate.t("post.stock_location"),
                        inputFormatters: [FirstLetterUpperCaseFormatter()],
                        hintText: Translate.t("post.stock_location_hint"),
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      // const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: _pincodeController,
                        label: Translate.t("post.pincode"),
                        hintText: '000000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return Translate.t(
                              "business_info.pincode_required",
                            );
                          }
                          if (value.length < 4) {
                            return Translate.t("business_info.pincode_min");
                          }
                          if (value.length > 12) {
                            return Translate.t("business_info.pincode_max");
                          }
                          return null;
                        },
                      ),
                      // const SizedBox(height: 16),
                      CustomTextFormField(
                        height: 150,
                        controller: descriptionController,
                        label: widget.role == "buyer"
                            ? Translate.t("post.remark")
                            : Translate.t("post.description"),
                        hintText: Translate.t("post.description_hint"),
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                      ),
                      // const SizedBox(height: 24),
                      _buildImageUploadSection(result),

                      _buildSectionHeader(
                        widget.role == "buyer"
                            ? Translate.t("post.Stock_supply_Dates")
                            : Translate.t("post.Stock_Availability_Dates"),
                      ),
                      const SizedBox(height: 8),

                      // --- UPDATED: pass errorText ---
                      _buildDatePickerTile(
                        title: orderDate == null
                            ? Translate.t("post.stock_available_from")
                            : "From: ${orderDate!.day}/${orderDate!.month}/${orderDate!.year}",
                        onTap: pickOrderDate,
                        errorText: orderDateError,
                      ),
                      const SizedBox(height: 8),
                      _buildDatePickerTile(
                        title: deliveryDate == null
                            ? allowLowerBids
                                  ? Translate.t("post.bidding_available_till")
                                  : Translate.t("post.stock_available_till")
                            : "Till: ${deliveryDate!.day}/${deliveryDate!.month}/${deliveryDate!.year}",
                        onTap: orderDate == null ? null : pickDeliveryDate,
                        isDisabled: orderDate == null,
                        errorText: deliveryDateError,
                      ),

                      const SizedBox(height: 8),
                      _buildSectionHeader(
                        Translate.t("post.additional_options"),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: CustomCheckbox(
                            value: allowLowerBids,
                            onChanged: (v) =>
                                setState(() => allowLowerBids = v ?? false),
                            label: widget.role == "buyer"
                                ? Translate.t("post.allow_negotiations")
                                : Translate.t("post.allow_negotiation"),
                          ),
                        ),
                      ),
                      // if (allowLowerBids == true) ...[
                      //   const SizedBox(height: 12),
                      //   _buildDatePickerTile(
                      //     title: validBiddingDate == null
                      //         ? Translate.t("post.bidding_available_till")
                      //         : "Till: ${validBiddingDate!.day}/${validBiddingDate!.month}/${validBiddingDate!.year}",
                      //     onTap: pickValidBiddingDate,
                      //     errorText: validBiddingDateError,
                      //   ),
                      // ],

                      // ─────────────────────────────────────────
                      // DESKTOP / TABLET LAYOUT
                      // ─────────────────────────────────────────
                    ] else ...[
                      if (hideGrade) ...[
                        _buildSectionHeader(
                          Translate.t("post.basic_information"),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!hideNutOutCrop)
                              Expanded(
                                child: CustomDropdownFormField<int>(
                                  isEnabled: editqty,
                                  value:
                                      selectedCropYear ?? DateTime.now().year,
                                  items: cropYears,
                                  prefixIcon: Icons.calendar_month,
                                  labels: cropYears.map((y) => '$y').toList(),
                                  label: Translate.t("post.crop_year"),
                                  onChanged: (v) => setState(() {
                                    selectedCropYear = v;
                                    orderDate = null;
                                    deliveryDate = null;
                                    cropYearError = null; // clear on change
                                  }),
                                  validator: (v) => v == null
                                      ? Translate.t("common.required")
                                      : null,
                                  isRequired: !hideNutOutCrop,
                                ),
                              ),
                            if (!hideNutOutCrop) const SizedBox(width: 8),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomDropdownFormField<String>(
                                value: selectedOrigin ?? userdata['country'],
                                items: origins,
                                labels: origins,
                                label: Translate.t("post.origin"),
                                onChanged: (v) => setState(() {
                                  selectedOrigin = v;
                                  originError = null; // clear on change
                                }),
                                prefixIcon: Icons.language,
                                validator: (v) => v == null ? "Required" : null,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                if (!hideGrade) ...[
                                  _buildSectionHeader(
                                    Translate.t("post.basic_information"),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomDropdownFormField<String>(
                                    value:
                                        selectedOrigin ?? userdata['country'],
                                    items: origins,
                                    labels: origins,
                                    label: Translate.t("post.origin"),
                                    onChanged: (v) => setState(() {
                                      selectedOrigin = v;
                                      originError = null; // clear on change
                                    }),
                                    prefixIcon: Icons.language,
                                    validator: (v) =>
                                        v == null ? "Required" : null,
                                    isRequired: true,
                                  ),
                                  const SizedBox(height: 8),
                                  CustomDropdownFormField<String>(
                                    isEnabled: editqty,
                                    value: selectedGrade ?? "W240",
                                    items: grades,
                                    labels: grades,
                                    label: Translate.t("post.grade"),
                                    onChanged: (v) => setState(() {
                                      selectedGrade = v;
                                      gradeError = null; // clear on change
                                    }),
                                    validator: (v) => !hideGrade && v == null
                                        ? "Required"
                                        : null,
                                    isRequired: !hideGrade,
                                    prefixIcon: Icons.category,
                                  ),
                                ],

                                const SizedBox(height: 16),
                                CustomDropdownFormField<String>(
                                  value: selectedsale,
                                  items: sale,
                                  labels: sale,
                                  label: "Sales *",
                                  onChanged: (v) => setState(() {
                                    selectedsale = v;
                                    if (v == "International") {
                                      setState(() {
                                        isshipment = true;
                                      });
                                    } else {
                                      setState(() {
                                        isshipment = false;
                                      });
                                    }
                                    saleError = null; // clear on change
                                  }),
                                  // prefixIcon: Icons.local_shipping,
                                  validator: (v) =>
                                      v == null ? "Required" : null,
                                  isRequired: true,
                                ),

                                if (hideGrade) ...[
                                  _buildSectionHeader(
                                    Translate.t("post.quality_specifications"),
                                  ),
                                  const SizedBox(height: 8),
                                ] else ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!hideCertificateHighSea) ...[
                                        _buildSectionHeader(
                                          Translate.t(
                                            "post.additional_options",
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: CustomCheckbox(
                                            value: certificate,
                                            onChanged: (v) => setState(
                                              () => certificate = v ?? false,
                                            ),
                                            label: Translate.t(
                                              "post.rbs_certificate",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (hideGrade) ...[
                                          SizedBox(
                                            width: double.infinity,
                                            child: CustomCheckbox(
                                              value: highSea,
                                              onChanged: (v) => setState(
                                                () => highSea = v ?? false,
                                              ),
                                              label: Translate.t(
                                                "post.high_sea",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomCheckbox(
                                          value: allowLowerBids,
                                          onChanged: (v) => setState(
                                            () => allowLowerBids = v ?? false,
                                          ),
                                          label: Translate.t(
                                            "post.allow_negotiation",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (!hideNutOutCrop) ...[
                                  CustomTextFormField(
                                    controller: nutCountController,
                                    label: Translate.t("post.nut_count"),
                                    hintText: "140 - 260",
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => handleNumericInput(
                                      nutCountController,
                                      'nutCount',
                                    ),
                                    validator: validateNutCount,
                                    errorText: nutCountError.isNotEmpty
                                        ? nutCountError
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextFormField(
                                    controller: outTurnController,
                                    label: Translate.t("post.out_turn"),
                                    hintText: "22 - 60",
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => handleNumericInput(
                                      outTurnController,
                                      'outTurn',
                                    ),
                                    validator: validateOutTurn,
                                    errorText: outTurnError.isNotEmpty
                                        ? outTurnError
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (hideGrade)
                                  CustomTextFormField(
                                    controller: moistureContentController,
                                    label: Translate.t("post.moisture_content"),
                                    hintText: Translate.t("post.moisture_hint"),
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => handleNumericInput(
                                      moistureContentController,
                                      'moistureContent',
                                    ),
                                    validator: validateMoistureContent,
                                    errorText: moistureError.isNotEmpty
                                        ? moistureError
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  Translate.t("post.quantity_pricing"),
                                ),
                                const SizedBox(height: 8),
                                CustomTextFormFieldright(
                                  controller: requiredQtyController,
                                  label: widget.role == "buyer"
                                      ? Translate.t("post.required_quantity")
                                      : Translate.t("post.available_quantity"),
                                  hintText: Translate.t("post.enter_quantity"),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    MinValueInputFormatter(confirmedkg),
                                    MaxValueInputFormatter(99999999),
                                  ],
                                  onChanged: (_) => handleNumericInput(
                                    requiredQtyController,
                                    'quantity',
                                  ),
                                  onVerifyPressed: () {
                                    // showUnitSelector(context, "unit");
                                  },
                                  suffixIcon: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      setState(() {
                                        unit = value;
                                      });
                                    },
                                    itemBuilder: (context) {
                                      return ['Kg', 'MT']
                                          .map(
                                            (currency) => PopupMenuItem<String>(
                                              value: currency,
                                              child: Text(currency),
                                            ),
                                          )
                                          .toList();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            unit,
                                            style: AppTextThemes
                                                .getLightTextTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  errorText: numberError.isNotEmpty
                                      ? numberError
                                      : null,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return Translate.t("post.value_required");
                                    }
                                    final intValue = int.tryParse(
                                      removeCommas(value),
                                    );
                                    if (intValue == null) {
                                      return Translate.t(
                                        "post.enter_valid_number",
                                      );
                                    }
                                    if (intValue < confirmedkg) {
                                      return Translate.t(
                                        "post.minimum_value",
                                      ).replaceAll("{value}", "$confirmedkg");
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                CustomTextFormFieldright(
                                  controller: minSupplyController,
                                  label: widget.role == "buyer"
                                      ? Translate.t(
                                          "post.minimum_supply_quantity",
                                        )
                                      : Translate.t(
                                          "post.minimum_order_quantity",
                                        ),
                                  hintText: Translate.t(
                                    "post.minimum_quantity",
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => handleNumericInput(
                                    minSupplyController,
                                    'minSupplyQuantity',
                                  ),
                                  // onVerifyPressed: () {
                                  //   setState(() {
                                  //     unit = unit == 'Kg' ? 'MT' : "Kg";
                                  //   });
                                  // },
                                  suffixIcon: IntrinsicWidth(
                                    child: Row(
                                      children: [
                                        // Icon(Icons.swap_vert, color: AppColors.primary),
                                        Text(
                                          unit,
                                          style: AppTextThemes
                                              .getLightTextTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.transparent,
                                        ),
                                      ],
                                    ),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? Translate.t("post.required")
                                      : null,

                                  errorText: numberError.isNotEmpty
                                      ? numberError
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                isshipment
                                    ? CustomDropdownFormField<String>(
                                        value: selectedsaleType,
                                        items: shipmentsaleTypes,
                                        labels: shipmentsaleTypes,
                                        label: Translate.t(
                                          "post.shipment_basis",
                                        ),
                                        onChanged: (v) => setState(() {
                                          selectedsaleType = v;
                                          shipmentsaleTypeError =
                                              null; // clear on change
                                        }),
                                        // prefixIcon: Icons.local_shipping,
                                        validator: (v) =>
                                            v == null ? "Required" : null,
                                        isRequired: true,
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            child: CustomCheckbox(
                                              label: "Inclusive of VAT/GST",
                                              value:
                                                  selectedsaleType ==
                                                      "Inclusive of VAT/GST"
                                                  ? true
                                                  : false,
                                              onChanged: (v) => setState(() {
                                                selectedsaleType = v == true
                                                    ? "Inclusive of VAT/GST"
                                                    : "Exclusive of VAT/GST";
                                                shipmentsaleTypeError =
                                                    null; // clear on change
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextFormFieldright(
                                        controller: expectedPriceController,
                                        label: widget.role == "buyer"
                                            ? Translate.t(
                                                "post.expected_selling_price_per_kg",
                                              )
                                            : Translate.t(
                                                "post.selling_price_per_kg",
                                              ),
                                        hintText: "0.00",
                                        onVerifyPressed: () {
                                          // showUnitSelector(context, "selectedpriceper");
                                          // setState(() {
                                          //   selectedpriceper = selectedpriceper == 'Kg'
                                          //       ? 'MT'
                                          //       : "Kg";
                                          // });
                                        },
                                        onprefixPressed: () {
                                          showCurrencySelector(
                                            context,
                                            "selected currency",
                                          );
                                          // setState(() {
                                          //   selectedpriceper = selectedpriceper == 'Kg'
                                          //       ? 'MT'
                                          //       : "Kg";
                                          // });
                                        },
                                        // prefixIcon: IntrinsicWidth(
                                        //   child: CustomDropdownFormField<String>(
                                        //     decoration: InputDecoration(
                                        //       // contentPadding: EdgeInsets.symmetric(
                                        //       //   horizontal: 8,
                                        //       //   vertical: 0,
                                        //       // ),
                                        //       suffixIcon: const Icon(
                                        //         Icons.arrow_drop_down,
                                        //         size: 20,
                                        //       ),
                                        //       border: OutlineInputBorder(
                                        //         borderSide: BorderSide(
                                        //           color: Colors.transparent,
                                        //         ),
                                        //       ),
                                        //     ),
                                        //     borderColor: Colors.transparent,
                                        //     value: selectedCurrency,
                                        //     items: currencies,
                                        //     labels: currencies,
                                        //     // label: Translate.t("post.currency"),
                                        //     labelStyle: const TextStyle(
                                        //       overflow: TextOverflow.ellipsis,
                                        //     ),
                                        //     onChanged: (v) => setState(() {
                                        //       selectedCurrency = v;
                                        //       currencyError = null; // clear on change
                                        //     }),
                                        //     validator: (v) =>
                                        //         v == null ? 'Required' : null,
                                        //     isRequired: true,
                                        //   ),
                                        // ),
                                        prefixIcon: PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) {
                                            setState(() {
                                              selectedCurrency = value;
                                            });
                                          },
                                          itemBuilder: (context) {
                                            return currencies
                                                .map(
                                                  (currency) =>
                                                      PopupMenuItem<String>(
                                                        value: currency,
                                                        child: Text(currency),
                                                      ),
                                                )
                                                .toList();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  selectedCurrency ?? "USD",
                                                  style: AppTextThemes
                                                      .getLightTextTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: AppColors.primary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        suffixIcon: PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) {
                                            setState(() {
                                              selectedpriceper = value;
                                            });
                                          },
                                          itemBuilder: (context) {
                                            return ['Kg', 'MT']
                                                .map(
                                                  (currency) =>
                                                      PopupMenuItem<String>(
                                                        value: currency,
                                                        child: Text(currency),
                                                      ),
                                                )
                                                .toList();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  selectedpriceper,
                                                  style: AppTextThemes
                                                      .getLightTextTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: AppColors.primary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => handleNumericInput(
                                          expectedPriceController,
                                          'expectedPrice',
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? "Required"
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _buildImageUploadSection(result),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildSectionHeader("Location & Availability"),
                                const SizedBox(height: 8),
                                CustomTextFormField(
                                  controller: cityController,
                                  label: Translate.t("post.stock_location"),
                                  hintText: "Enter city/location name",
                                  inputFormatters: [
                                    FirstLetterUpperCaseFormatter(),
                                  ],
                                  keyboardType: TextInputType.text,
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Required"
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                CustomTextFormField(
                                  controller: _pincodeController,
                                  label: Translate.t("post.pincode"),
                                  hintText: '000000',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return Translate.t(
                                        "business_info.pincode_required",
                                      );
                                    }
                                    if (value.length < 4) {
                                      return Translate.t(
                                        "business_info.pincode_min",
                                      );
                                    }
                                    if (value.length > 12) {
                                      return Translate.t(
                                        "business_info.pincode_max",
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                CustomTextFormField(
                                  height: 150,
                                  controller: descriptionController,
                                  label: Translate.t("post.description"),
                                  hintText: Translate.t(
                                    "post.description_hint",
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                _buildSectionHeader(
                                  Translate.t("post.Stock_Availability_Dates"),
                                ),
                                const SizedBox(height: 8),

                                // --- UPDATED: pass errorText ---
                                _buildDatePickerTile(
                                  title: orderDate == null
                                      ? Translate.t("post.stock_available_from")
                                      : "From: ${orderDate!.day}/${orderDate!.month}/${orderDate!.year}",
                                  onTap: pickOrderDate,
                                  errorText: orderDateError,
                                ),
                                const SizedBox(height: 8),
                                _buildDatePickerTile(
                                  title: deliveryDate == null
                                      ? Translate.t("post.stock_available_till")
                                      : "Till: ${deliveryDate!.day}/${deliveryDate!.month}/${deliveryDate!.year}",
                                  onTap: orderDate == null
                                      ? null
                                      : pickDeliveryDate,
                                  isDisabled: orderDate == null,
                                  errorText: deliveryDateError,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      if (hideGrade) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!hideCertificateHighSea) ...[
                              _buildSectionHeader(
                                Translate.t("post.additional_options"),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: CustomCheckbox(
                                  value: certificate,
                                  onChanged: (v) =>
                                      setState(() => certificate = v ?? false),
                                  label: Translate.t("post.rbs_certificate"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // if (hideGrade) ...[
                              //   SizedBox(
                              //     width: double.infinity,
                              //     child: CustomCheckbox(
                              //       value: highSea,
                              //       onChanged: (v) =>
                              //           setState(() => highSea = v ?? false),
                              //       label: Translate.t("post.high_sea"),
                              //     ),
                              //   ),
                              //   const SizedBox(height: 12),
                              // ],
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: CustomCheckbox(
                                value: allowLowerBids,
                                onChanged: (v) =>
                                    setState(() => allowLowerBids = v ?? false),
                                label: Translate.t("post.allow_negotiation"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    CustomSubmitButton(
                      width: 400,
                      label: widget.isEdit
                          ? (widget.role == 'buyer'
                                ? Translate.t("post.update_requirement")
                                : Translate.t("post.update_stock"))
                          : (widget.role == 'buyer'
                                ? Translate.t("post.post_requirement")
                                : Translate.t("post.post_stock")),
                      onPressed: isLoading ? null : saveRequirement,
                      isLoading: isLoading,
                      height: 56,
                      borderRadius: 12,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class MinValueInputFormatter extends TextInputFormatter {
  final int minValue;

  MinValueInputFormatter(this.minValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < minValue) return oldValue;
    return newValue;
  }
}
