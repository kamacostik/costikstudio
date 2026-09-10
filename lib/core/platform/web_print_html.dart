// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void printHtmlDocument({required String title, required String htmlContent}) {
  final escapedTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = '$escapedTitle.html'
    ..click();

  Future<void>.delayed(const Duration(seconds: 5), () {
    html.Url.revokeObjectUrl(url);
  });
}
