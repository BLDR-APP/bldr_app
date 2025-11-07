import 'package:flutter/material.dart';

class ProfileNotifier extends ChangeNotifier {
  /// Este método age como um "sinal" para qualquer parte do app
  /// que esteja ouvindo, avisando que o perfil do usuário foi alterado.
  void notifyProfileUpdated() {
    notifyListeners();
  }
}