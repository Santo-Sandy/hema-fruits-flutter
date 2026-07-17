extension StringExt on String {
  String get capitalize =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');
  String get initials => trim()
      .split(' ')
      .take(2)
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
      .join();
  bool get isEmail => RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(this);
}

extension StringNullExt on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}
