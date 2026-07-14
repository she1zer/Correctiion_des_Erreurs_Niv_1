import 'dart:convert';
import 'dart:io' show Platform;

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../config/google_config.dart';

/// Résumé d'un email Gmail pour l'écran devis.
class GmailMessageSummary {
  final String messageId;
  final String subject;
  final String fromAddress;
  final String? fromName;
  final String date;
  final String preview;
  final String body;
  final String htmlBody;
  final List<String> references;

  GmailMessageSummary({
    required this.messageId,
    required this.subject,
    required this.fromAddress,
    this.fromName,
    required this.date,
    required this.preview,
    required this.body,
    this.htmlBody = '',
    this.references = const [],
  });

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'subject': subject,
        'from_address': fromAddress,
        'from_name': fromName,
        'date': date,
        'preview': preview,
        'body': body,
        'html_body': htmlBody,
        'references': references,
      };
}

/// Connexion Gmail OAuth et lecture de la boîte de réception.
class GmailService {
  static final GmailService instance = GmailService._();
  GmailService._();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [GoogleConfig.gmailReadonlyScope],
    serverClientId: GoogleConfig.webClientId,
    clientId: (!kIsWeb && Platform.isAndroid) ? null : GoogleConfig.androidClientId,
  );

  GoogleSignInAccount? _account;
  gmail.GmailApi? _api;

  GoogleSignInAccount? get account => _account;
  bool get isSignedIn => _account != null;

  /// Message d'aide pour l'erreur Google Sign-In ApiException 10 (DEVELOPER_ERROR).
  static String friendlySignInError(Object error) {
    final msg = error.toString();
    if (msg.contains('ApiException: 10') || msg.contains('sign_in_failed')) {
      return 'Configuration Google OAuth incorrecte (erreur 10).\n\n'
          '1. Google Cloud Console → projet appisitek\n'
          '2. Identifiants → client OAuth Android com.isitek.app\n'
          '3. Ajoutez l\'empreinte SHA-1 du keystore debug :\n'
          '   keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android\n'
          '4. Client Web configuré (Isitek Web Client) — serverClientId OK\n'
          '5. Ajoutez isitek.sarl@gmail.com comme utilisateur test OAuth\n\n'
          'En attendant, utilisez le collage manuel d\'email ci-dessus.';
    }
    if (msg.contains('12500') || msg.contains('SIGN_IN_CANCELLED')) {
      return 'Connexion annulée.';
    }
    return 'Connexion Gmail impossible : $error';
  }

  /// Message court pour les erreurs Gmail API (403, quota, etc.).
  static String friendlyApiError(Object error) {
    final msg = error.toString();
    if (msg.contains('403') &&
        (msg.contains('Gmail API has not been used') ||
            msg.contains('Gmail API') && msg.contains('disabled'))) {
      return 'API Gmail activée — propagation en cours (2 à 5 min).\n'
          'Appuyez sur Actualiser dans quelques minutes.\n\n'
          'Projet : appisitek (836819597580)';
    }
    if (msg.contains('403')) {
      return 'Accès Gmail refusé (403).\n'
          'Vérifiez que isitek.sarl@gmail.com est utilisateur test OAuth '
          'et que le scope gmail.readonly est autorisé.';
    }
    if (msg.contains('401')) {
      return 'Session Gmail expirée — déconnectez-vous puis reconnectez-vous.';
    }
    if (msg.length > 320) return '${msg.substring(0, 320)}…';
    return msg;
  }

  Future<bool> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      if (_account == null) return false;
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return false;
      _api = gmail.GmailApi(client);
      return true;
    } on PlatformException catch (e) {
      throw GmailSignInException(friendlySignInError(e));
    } catch (e) {
      throw GmailSignInException(friendlySignInError(e));
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _api = null;
  }

  Future<List<GmailMessageSummary>> fetchInbox({int maxResults = 20}) async {
    if (_api == null) throw StateError('Gmail non connecté');

    try {
      final list = await _api!.users.messages.list(
        'me',
        maxResults: maxResults,
        labelIds: ['INBOX'],
      );

      final messages = list.messages ?? [];
      final results = <GmailMessageSummary>[];

      for (final msg in messages) {
        if (msg.id == null) continue;
        final full = await _api!.users.messages.get(
          'me',
          msg.id!,
          format: 'full',
        );
        final parsed = _parseMessage(full);
        if (parsed != null) results.add(parsed);
      }
      return results;
    } catch (e) {
      throw GmailApiException(friendlyApiError(e));
    }
  }

  GmailMessageSummary? _parseMessage(gmail.Message message) {
    final headers = message.payload?.headers ?? [];
    String header(String name) {
      for (final h in headers) {
        if (h.name?.toLowerCase() == name.toLowerCase()) {
          return h.value ?? '';
        }
      }
      return '';
    }

    final subject = header('Subject');
    final fromRaw = header('From');
    final date = header('Date');
    final (fromAddress, fromName) = _parseFrom(fromRaw);
    final plainBody = _extractPlainBody(message.payload);
    final htmlBody = _extractHtmlBody(message.payload);
    final bodyForRefs = plainBody.isNotEmpty ? plainBody : _stripHtml(htmlBody);
    final preview = bodyForRefs.replaceAll(RegExp(r'\s+'), ' ').trim();
    final refs = _extractRefs('$subject\n$bodyForRefs');

    return GmailMessageSummary(
      messageId: message.id ?? '',
      subject: subject,
      fromAddress: fromAddress,
      fromName: fromName,
      date: date,
      preview: preview.length > 220 ? preview.substring(0, 220) : preview,
      body: plainBody.isNotEmpty ? plainBody : _stripHtml(htmlBody),
      htmlBody: htmlBody,
      references: refs,
    );
  }

  (String, String?) _parseFrom(String fromHeader) {
    final match = RegExp(r'"?([^"<]*)"?\s*<([^>]+)>').firstMatch(fromHeader);
    if (match != null) {
      final name = match.group(1)?.trim();
      return (match.group(2)!.trim(), name != null && name.isNotEmpty ? name : null);
    }
    return (fromHeader.trim(), null);
  }

  String _extractPlainBody(gmail.MessagePart? part) {
    if (part == null) return '';

    if (part.mimeType == 'text/plain' &&
        part.body?.data != null &&
        part.body!.data!.isNotEmpty) {
      return _decodeBase64(part.body!.data!);
    }

    if (part.parts != null) {
      for (final sub in part.parts!) {
        if (sub.mimeType == 'text/plain') {
          final text = _extractPlainBody(sub);
          if (text.isNotEmpty) return text;
        }
      }
      for (final sub in part.parts!) {
        final text = _extractPlainBody(sub);
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  String _extractHtmlBody(gmail.MessagePart? part) {
    if (part == null) return '';

    if (part.mimeType == 'text/html' &&
        part.body?.data != null &&
        part.body!.data!.isNotEmpty) {
      return _decodeBase64(part.body!.data!);
    }

    if (part.parts != null) {
      for (final sub in part.parts!) {
        if (sub.mimeType == 'text/html') {
          final html = _extractHtmlBody(sub);
          if (html.isNotEmpty) return html;
        }
      }
      for (final sub in part.parts!) {
        final html = _extractHtmlBody(sub);
        if (html.isNotEmpty) return html;
      }
    }
    return '';
  }

  String _stripHtml(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _extractBody(gmail.MessagePart? part) {
    final plain = _extractPlainBody(part);
    if (plain.isNotEmpty) return plain;
    return _stripHtml(_extractHtmlBody(part));
  }

  String _decodeBase64(String data) {
    try {
      final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(
        normalized.length + (4 - normalized.length % 4) % 4,
        '=',
      );
      return utf8.decode(base64.decode(padded));
    } catch (_) {
      return '';
    }
  }

  List<String> _extractRefs(String text) {
    final pattern = RegExp(
      r'\b(?:REF|RÉF|REFERENCE|RÉFÉRENCE|ART|ARTICLE|CODE|P/N|PN|MOD(?:EL)?\.?)\s*[:#]?\s*([A-Z0-9][A-Z0-9\-./]{2,})\b',
      caseSensitive: false,
    );
    final refs = <String>{};
    for (final m in pattern.allMatches(text.toUpperCase())) {
      refs.add(m.group(1)!.toUpperCase());
    }
    return refs.toList();
  }
}

class GmailSignInException implements Exception {
  final String message;
  GmailSignInException(this.message);
  @override
  String toString() => message;
}

class GmailApiException implements Exception {
  final String message;
  GmailApiException(this.message);
  @override
  String toString() => message;
}
