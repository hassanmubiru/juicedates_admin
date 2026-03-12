import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JuiceDatesAdminApp());
}

class JuiceDatesAdminApp extends StatelessWidget {
  const JuiceDatesAdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JuiceDates Admin',
      theme: adminTheme(),
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData) return const _AdminCheck();
        return const LoginScreen();
      },
    );
  }
}

class _AdminCheck extends StatefulWidget {
  const _AdminCheck();
  @override
  State<_AdminCheck> createState() => _AdminCheckState();
}

class _AdminCheckState extends State<_AdminCheck> {
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        await FirebaseAuth.instance.signOut();
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final isAdmin = (doc.data()?['isAdmin'] as bool?) ?? false;
      if (!isAdmin) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied — admin accounts only.'),
              backgroundColor: kDanger,
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _verified = true);
    } catch (e) {
      // Network / Firestore error — sign out and show message
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in error: $e'),
            backgroundColor: kDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_verified) return const _SplashScreen();
    return const AdminShell();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: kTangerine,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: kTangerine),
          ],
        ),
      ),
    );
  }
}
