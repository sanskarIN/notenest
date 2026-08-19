import 'package:url_launcher/url_launcher.dart';

typedef ExternalLaunchDelegate = Future<bool> Function(
  Uri uri,
  LaunchMode mode,
);

final class ExternalLinkService {
  ExternalLinkService({ExternalLaunchDelegate? launcher})
      : _launcher = launcher ?? _defaultLaunch;

  final ExternalLaunchDelegate _launcher;

  Future<bool> open(
    Uri uri, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    try {
      return await _launcher(uri, mode);
    } on Object {
      return false;
    }
  }

  static Future<bool> _defaultLaunch(Uri uri, LaunchMode mode) {
    return launchUrl(uri, mode: mode);
  }
}
