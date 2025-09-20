import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() {
    return WebDatabase('training_app');
  }));
}