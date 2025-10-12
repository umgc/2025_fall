/// Model class representing a physical address.
///
/// This class encapsulates address information including street address,
/// city, state, ZIP code, and optional phone number. It provides JSON
/// serialization capabilities for API communication and data persistence.
class Address {
  /// First line of the street address (required)
  final String line1;

  /// Second line of the street address (apartment, suite, etc.)
  final String line2;

  /// City name
  final String city;

  /// State or province name
  final String state;

  /// ZIP or postal code
  final String zip;

  /// Optional phone number associated with this address
  final String? phone;

  /// Creates a new Address instance.
  ///
  /// Parameters:
  /// * [line1] - First line of the street address (required)
  /// * [line2] - Second line of the street address (apartment, suite, etc.)
  /// * [city] - City name
  /// * [state] - State or province name
  /// * [zip] - ZIP or postal code
  /// * [phone] - Optional phone number associated with this address
  Address({
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.zip,
    this.phone,
  });

  /// Converts the Address instance to a JSON map.
  ///
  /// Used for API requests and data serialization. All fields are included
  /// in the JSON output, with null phone numbers preserved.
  ///
  /// Returns:
  /// * Map<String, dynamic> - JSON representation of the address
  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'zip': zip,
      'phone': phone,
    };
  }

  /// Creates an Address instance from a JSON map.
  ///
  /// Factory constructor that handles JSON deserialization from API responses.
  /// Provides default empty strings for missing required fields and handles
  /// null values appropriately.
  ///
  /// Parameters:
  /// * [json] - JSON map containing address data
  ///
  /// Returns:
  /// * Address - New Address instance populated from JSON data
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      line1: json['line1'] ?? '',
      line2: json['line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zip: json['zip'] ?? '',
      phone: json['phone'],
    );
  }
}
