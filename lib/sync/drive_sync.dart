/// Google Drive backup / restore.
///
/// Stores a single JSON file in the Drive *appDataFolder* (a private, app-only
/// folder), so no extra Drive permissions are surfaced to the user beyond the
/// app's own hidden config.
library;

import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:toji_trainer/data/database.dart';

class SyncResult {
  const SyncResult(this.ok, this.message);
  final bool ok;
  final String message;
}

class DriveSync {
  DriveSync(this._db);
  final AppDatabase _db;

  static const _fileName = 'toji_trainer_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _account;
  bool get isSignedIn => _account != null;
  String? get userEmail => _account?.email;

  Future<GoogleSignInAccount?> signIn() async {
    _account = await _googleSignIn.signIn();
    return _account;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  Future<bool> _ensureAuth() async {
    _account ??= await _googleSignIn.signInSilently();
    return _account != null;
  }

  Future<drive.DriveApi?> _api() async {
    if (!await _ensureAuth()) return null;
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  /// Export local DB and upload/overwrite the backup file on Drive.
  Future<SyncResult> backup() async {
    try {
      final api = await _api();
      if (api == null) {
        return const SyncResult(false, 'Gagal login ke Google.');
      }
      final json = await _db.exportJson();
      final bytes = utf8.encode(json);

      // Look for an existing backup in appDataFolder.
      final existing = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_fileName'",
      );
      final fileId = (existing.files != null && existing.files!.isNotEmpty)
          ? existing.files!.first.id
          : null;

      final media = drive.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
      );

      if (fileId != null) {
        await api.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        final meta = drive.File()
          ..name = _fileName
          ..parents = ['appDataFolder'];
        await api.files.create(meta, uploadMedia: media);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.saveSyncMeta(lastSyncAt: now, driveFileId: fileId ?? _fileName);
      return const SyncResult(true, 'Backup berhasil ke Google Drive.');
    } catch (e) {
      return SyncResult(false, 'Backup gagal: $e');
    }
  }

  /// Download the backup from Drive and import into the local DB.
  Future<SyncResult> restore({bool merge = true}) async {
    try {
      final api = await _api();
      if (api == null) {
        return const SyncResult(false, 'Gagal login ke Google.');
      }
      final existing = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_fileName'",
      );
      if (existing.files == null || existing.files!.isEmpty) {
        return const SyncResult(false, 'Belum ada backup di Drive.');
      }
      final fileId = existing.files!.first.id!;
      final media = await api.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final chunks = <int>[];
      await for (final c in media.stream) {
        chunks.addAll(c);
      }
      final jsonStr = utf8.decode(chunks);
      await _db.importJson(jsonStr, merge: merge);

      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.saveSyncMeta(lastSyncAt: now, driveFileId: fileId);
      return const SyncResult(true, 'Restore berhasil dari Google Drive.');
    } catch (e) {
      return SyncResult(false, 'Restore gagal: $e');
    }
  }
}
