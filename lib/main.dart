import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are fetched at runtime via google_fonts; set to false and bundle
  // the .ttf files under assets/fonts for fully offline builds.
  GoogleFonts.config.allowRuntimeFetching = true;
  await initializeDateFormatting('en_IN');
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const LifeMitraApp());
}
