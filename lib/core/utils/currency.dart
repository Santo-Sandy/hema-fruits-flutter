String getCurrencySymbol(String? currency) {
  final symbols = {'USD': '\$', 'INR': '₹', 'EUR': '€'};

  return symbols[currency?.toUpperCase()] ?? currency ?? '';
}
