import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final navigatorKeyProvider = Provider((ref) => GlobalKey<NavigatorState>());