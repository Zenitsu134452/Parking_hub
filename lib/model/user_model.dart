class UserModel {
  String name, email, phone, vehicleNumber, vehicleType;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleType,
  });

  // Convert JSON to object model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json["name"] ?? "User",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      vehicleNumber: json["vehicle_number"] ?? "",
      vehicleType: json["vehicle_type"] ?? "",
    );
  }
}
