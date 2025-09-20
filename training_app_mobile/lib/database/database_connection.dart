import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

// Conditional imports
import 'database_connection_stub.dart'
  if (dart.library.io) 'database_connection_mobile.dart'
  if (dart.library.html) 'database_connection_web.dart';

DatabaseConnection openConnection() {
  return connect();
}