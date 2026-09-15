import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final selectedLocaleProvider =
    StateProvider<Locale>((ref) => const Locale('en'));

final selectedRoleProvider =
    StateProvider<String>((ref) => 'patient');
