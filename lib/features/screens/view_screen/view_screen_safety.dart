Map<String, dynamic> safeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> safeList(dynamic value) {
  return value is List ? value : <dynamic>[];
}

String safeString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<dynamic> extractResponseList(dynamic response) {
  final data = safeList(safeMap(response)['data']);
  if (data.isEmpty) return <dynamic>[];
  return safeList(safeMap(data.first)['response']);
}

Map<String, dynamic> findResponseById(List<dynamic> responses, String id) {
  for (final response in responses) {
    final map = safeMap(response);
    if (map['_id']?.toString() == id) return map;
  }
  return <String, dynamic>{};
}

List<String> safeRoutePair(List<String> values) {
  return [
    values.isNotEmpty ? values[0] : '',
    values.length > 1 ? values[1] : '',
  ];
}

dynamic firstMapValue(dynamic list, String key) {
  final values = safeList(list);
  if (values.isEmpty) return null;
  return safeMap(values.first)[key];
}
