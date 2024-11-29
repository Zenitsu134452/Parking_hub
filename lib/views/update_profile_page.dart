import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_service.dart';
import '../controllers/db_service.dart';
import '../provider/user_provider.dart';

class UpdateProfilePage extends StatefulWidget {
  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _vehicleNumberController.text=user.vehicleNumber;
    _vehicleTypeController.text = user.vehicleType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Profile"),
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: "Name",
                              hintText: "Name",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                          value!.isEmpty ? "Name cannot be empty" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: const InputDecoration(
                              labelText: "Email",
                              hintText: "Email",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                          value!.isEmpty ? "Email cannot be empty." : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                              labelText: "Phone no",
                              hintText: "Phone no",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                          value!.isEmpty ? "Phone no cannot be empty." : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _vehicleNumberController,
                          decoration: const InputDecoration(
                              labelText: "Vehicle Number",
                              hintText: "Vehicle Number",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                          value!.isEmpty ? "Vehicle cannot be empty." : null,
                        ),
                        TextFormField(
                          controller: _vehicleTypeController,
                          decoration: const InputDecoration(
                              labelText: "Vehicle Type",
                              hintText: "Vehicle Type",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                          value!.isEmpty ? "Vehicle Type cannot be empty." : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final data = {
                                "name": _nameController.text,
                                "vehicle_number": _vehicleNumberController.text,
                                "phone": _phoneController.text,
                                "vehicle_type":_vehicleTypeController.text,
                              };

                              await DbService().updateUserData(extraData: data);
                              Provider.of<UserProvider>(context, listen: false)
                                  .loadUserData(AuthService().getCurrentUserId()!);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Profile Updated")));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white),
                          child: const Text(
                            "Update Profile",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
