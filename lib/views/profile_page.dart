import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_service.dart';
import '../provider/user_provider.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        leading: Icon(Icons.person),
        title: Text("Profile"),
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Card(
            child: ListTile(
              title: Text(userProvider.name),
              subtitle: Text(userProvider.email.isNotEmpty
                  ? userProvider.email
                  : "No Email"),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () {
                Navigator.pushNamed(context, "/update_profile");
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text("Phone no"),
              subtitle: Text(userProvider.phone.isNotEmpty
                  ? userProvider.phone
                  : "No Phone no"),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text("Vehicle Number"),
              subtitle: Text(userProvider.vehicleNumber.isNotEmpty
                  ? userProvider.vehicleNumber
                  : "No Vehicle number"),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text("Vehicle Type"),
              subtitle: Text(userProvider.vehicleType.isNotEmpty
                  ? userProvider.vehicleType
                  : "No Vehicle Type"),
            ),
          ),
          SizedBox(height: 20,),
          Divider( thickness: 1,  endIndent:  10, indent: 10,),
          Divider( thickness: 1,  endIndent:  10, indent: 10,),
          ListTile(title: Text("Help & Support"), leading: Icon(Icons.support_agent), onTap: (){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mail us at ecommerce@shop.com")));
          },),
          Divider( thickness: 1,  endIndent:  10, indent: 10,),
          ListTile(
            title: const Text("Logout"),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await AuthService().logout(
                    () => userProvider.resetUserData(),
              );
              Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
            },
          ),
        ],
      ),
    );
  }
}
