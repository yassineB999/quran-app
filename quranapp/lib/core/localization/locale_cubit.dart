import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit() : super(const Locale('fr'));

  void setLocale(Locale locale) {
    emit(locale);
  }

  void clearLocale() {
    emit(null);
  }
}
