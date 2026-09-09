import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/game_session.dart';
import '../domain/models/player.dart';
import 'game_session_repository.dart';

class SharedPreferencesSessionRepository implements GameSessionRepository {
  SharedPreferencesSessionRepository(this._prefs);

  static const _storageKey = 'game_sessions_v1';
  static const _activeKey = 'active_game_id';
  static const _rosterKey = 'game_rosters_v1';

  final SharedPreferences _prefs;

  @override
  Future<GameSession?> load(String gameId) async {
    final sessions = await loadAll();
    return sessions[gameId];
  }

  @override
  Future<Map<String, GameSession>> loadAll() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return {};
    }

    final sessions = <String, GameSession>{};
    for (final entry in decoded.entries) {
      if (entry.value is! Map) {
        continue;
      }
      final session = GameSession.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      sessions[entry.key as String] = session;
    }
    return sessions;
  }

  @override
  Future<void> save(GameSession session) async {
    final sessions = await loadAll();
    sessions[session.gameId] = session;
    await _write(sessions);
  }

  @override
  Future<void> delete(String gameId) async {
    final sessions = await loadAll();
    sessions.remove(gameId);
    await _write(sessions);
    final active = await loadActiveGameId();
    if (active == gameId) {
      await saveActiveGameId(null);
    }
  }

  @override
  Future<String?> loadActiveGameId() async {
    final id = _prefs.getString(_activeKey);
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  @override
  Future<void> saveActiveGameId(String? gameId) async {
    if (gameId == null || gameId.isEmpty) {
      await _prefs.remove(_activeKey);
      return;
    }
    await _prefs.setString(_activeKey, gameId);
  }

  @override
  Future<List<Player>> loadRoster(String gameId) async {
    final raw = _prefs.getString(_rosterKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const [];
    }
    final roster = decoded[gameId];
    if (roster is! List) {
      return const [];
    }
    return [
      for (final item in roster)
        if (item is Map) Player.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> saveRoster(String gameId, List<Player> players) async {
    final raw = _prefs.getString(_rosterKey);
    final decoded = raw == null || raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    map[gameId] = [for (final player in players) player.toJson()];
    await _prefs.setString(_rosterKey, jsonEncode(map));
  }

  Future<void> _write(Map<String, GameSession> sessions) async {
    final encoded = jsonEncode({
      for (final entry in sessions.entries) entry.key: entry.value.toJson(),
    });
    await _prefs.setString(_storageKey, encoded);
  }
}
