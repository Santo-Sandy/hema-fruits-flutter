class DeviceInfo {
  final String? id;
  final String? model;
  final String? brand;
  final String? device;
  final String? sdk;

  DeviceInfo({this.id, this.model, this.brand, this.device, this.sdk});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'brand': brand,
      'device': device,
      'sdk': sdk,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'],
      model: json['model'],
      brand: json['brand'],
      device: json['device'],
      sdk: json['sdk'],
    );
  }
}
