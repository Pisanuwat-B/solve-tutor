import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/widgets/sizer.dart';

class NoPermissionPage extends StatefulWidget {
  const NoPermissionPage({super.key});

  @override
  State<NoPermissionPage> createState() => _NoPermissionPageState();
}

class _NoPermissionPageState extends State<NoPermissionPage> {
  AuthProvider? authprovider;
  @override
  Widget build(BuildContext context) {
    authprovider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: Container(
        width: Sizer(context).w,
        height: Sizer(context).h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No permission"),
            SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await authprovider!.signOut();
                },
                backgroundColor: Colors.redAccent,
                icon: const Icon(Icons.logout),
                label: const Text('กลับสู่หน้า Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
