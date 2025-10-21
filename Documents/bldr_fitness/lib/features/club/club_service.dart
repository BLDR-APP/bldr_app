import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class BldrClubProgramsService {
  BldrClubProgramsService(this._client);
  final SupabaseClient _client;

  Future<List<ClubProgram>> listPrograms({int from = 0, int to = 19}) async {
    final data = await _client
        .schema('bldr_club')
        .from('programs')
        .select(
        'id, slug, name, tagline, description, level, duration_weeks, '
            'minutes_per_day, sessions_per_week, equipment, tags, cover_image, created_at'
    )
        .eq('is_active', true)
        .order('name', ascending: true)
        .range(from, to);

    return (data as List).map((m) => ClubProgram.fromMap(m)).toList();
  }

  Future<(ClubProgram, List<(ClubSession, List<ClubExercise>)>)> getProgramDetail(
      String programId) async {
    final pData = await _client
        .schema('bldr_club')
        .from('programs')
        .select(
        'id, slug, name, tagline, description, level, duration_weeks, '
            'minutes_per_day, sessions_per_week, equipment, tags, cover_image'
    )
        .eq('id', programId)
        .single();

    final sessions = await _client
        .schema('bldr_club')
        .from('program_sessions')
        .select('id, title, focus, order_index, program_id')
        .eq('program_id', programId)
        .order('order_index', ascending: true);

    final sessionModels =
    (sessions as List).map((m) => ClubSession.fromMap(m)).toList();
    final sessionIds = sessionModels.map((s) => s.id).toList();

    final exs = sessionIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
        .schema('bldr_club')
        .from('session_exercises')
        .select(
        'id, session_id, name, sets, reps, seconds, tempo, rest_sec, notes, order_index'
    )
        .filter('session_id', 'in', '(${sessionIds.map((e) => '"$e"').join(',')})')
        .order('order_index', ascending: true);

    final exBySession = <String, List<ClubExercise>>{};
    for (final row in (exs as List)) {
      final sid = row['session_id'] as String;
      (exBySession[sid] ??= []).add(ClubExercise.fromMap(row));
    }

    final program = ClubProgram.fromMap(pData);
    final result = sessionModels
        .map((s) => (s, exBySession[s.id] ?? const <ClubExercise>[]))
        .toList();

    return (program, result);
  }
}
