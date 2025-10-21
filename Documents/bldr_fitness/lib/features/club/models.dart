// BLDR CLUB – Models

enum ProgramLevel { iniciantes, intermediario, avancado, todos }

ProgramLevel parseLevel(String v) {
  switch (v) {
    case 'Iniciantes': return ProgramLevel.iniciantes;
    case 'Intermediário': return ProgramLevel.intermediario;
    case 'Avançado': return ProgramLevel.avancado;
    default: return ProgramLevel.todos;
  }
}

String levelLabel(ProgramLevel l) {
  switch (l) {
    case ProgramLevel.iniciantes: return 'Iniciantes';
    case ProgramLevel.intermediario: return 'Intermediário';
    case ProgramLevel.avancado: return 'Avançado';
    case ProgramLevel.todos: return 'Todos os níveis';
  }
}

class ClubProgram {
  final String id;
  final String slug;
  final String name;
  final String? tagline;
  final String? description;
  final ProgramLevel level;
  final int durationWeeks;
  final int minutesPerDay;
  final int sessionsPerWeek;
  final List<String> equipment;
  final List<String> tags;
  final String? coverImage;

  ClubProgram({
    required this.id,
    required this.slug,
    required this.name,
    required this.level,
    required this.durationWeeks,
    required this.minutesPerDay,
    required this.sessionsPerWeek,
    required this.equipment,
    required this.tags,
    this.tagline,
    this.description,
    this.coverImage,
  });

  factory ClubProgram.fromMap(Map<String, dynamic> m) {
    return ClubProgram(
      id: m['id'],
      slug: m['slug'],
      name: m['name'],
      tagline: m['tagline'],
      description: m['description'],
      level: parseLevel(m['level']),
      durationWeeks: m['duration_weeks'],
      minutesPerDay: m['minutes_per_day'],
      sessionsPerWeek: m['sessions_per_week'],
      equipment: (m['equipment'] as List?)?.cast<String>() ?? const [],
      tags: (m['tags'] as List?)?.cast<String>() ?? const [],
      coverImage: m['cover_image'],
    );
  }
}

class ClubSession {
  final String id;
  final String title;
  final String? focus;
  final int orderIndex;

  ClubSession({required this.id, required this.title, this.focus, required this.orderIndex});

  factory ClubSession.fromMap(Map<String, dynamic> m) => ClubSession(
    id: m['id'],
    title: m['title'],
    focus: m['focus'],
    orderIndex: m['order_index'],
  );
}

class ClubExercise {
  final String id;
  final String name;
  final int sets;
  final String? reps;
  final int? seconds;
  final String? tempo;
  final int restSec;
  final String? notes;

  ClubExercise({
    required this.id,
    required this.name,
    required this.sets,
    this.reps,
    this.seconds,
    this.tempo,
    required this.restSec,
    this.notes,
  });

  factory ClubExercise.fromMap(Map<String, dynamic> m) => ClubExercise(
    id: m['id'],
    name: m['name'],
    sets: m['sets'],
    reps: m['reps'],
    seconds: m['seconds'],
    tempo: m['tempo'],
    restSec: m['rest_sec'] ?? 60,
    notes: m['notes'],
  );
}
