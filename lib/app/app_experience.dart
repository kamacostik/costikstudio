import 'package:flutter/widgets.dart';

class AppExperienceScope extends InheritedWidget {
  const AppExperienceScope({
    super.key,
    required this.experience,
    required super.child,
  });

  final AppExperience experience;

  static AppExperience of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppExperienceScope>()
            ?.experience ??
        AppExperience.user;
  }

  @override
  bool updateShouldNotify(AppExperienceScope oldWidget) {
    return oldWidget.experience != experience;
  }
}

enum AppExperience { user, admin, adb }
