// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void openExternalUrl(String url) {
  html.window.open(url, '_blank');
}

void navigateToExternalUrl(String url) {
  html.window.location.assign(url);
}
