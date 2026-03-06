import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'reports_screen.dart';
import 'moments_screen.dart';
import 'notifications_screen.dart';
import 'winks_screen.dart';

/// Navigation items definition
const _navItems = [
  _NavItem(icon: Icons.dashboard_rounded,          label: 'Dashboard'),
  _NavItem(icon: Icons.people_rounded,              label: 'Users'),
  _NavItem(icon: Icons.flag_rounded,                label: 'Reports'),