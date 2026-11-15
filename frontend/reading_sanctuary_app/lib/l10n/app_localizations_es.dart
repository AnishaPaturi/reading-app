// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Reading Sanctuary';

  @override
  String get audiobooks => 'Audiolibros';

  @override
  String get audiobookSubtitle => 'Tu biblioteca personal de escucha';

  @override
  String get searchAudiobooksHint => 'Buscar libros y autores...';

  @override
  String get statusAll => 'Todos';

  @override
  String get statusCurrent => 'En curso';

  @override
  String get statusNotStarted => 'No iniciado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get continueListening => 'Continuar escuchando';

  @override
  String get allAudiobooks => 'Todos los audiolibros';

  @override
  String get import => 'Importar';

  @override
  String get importAudiobook => 'Importar audiolibro';

  @override
  String get importDescription =>
      'Trae tus propios audiolibros sin DRM. Compatible con MP3, M4B, M4A, OGG, OPUS.';

  @override
  String get scanFolder => 'Escanear carpeta';

  @override
  String get pickFiles => 'Elegir archivos';

  @override
  String get proposedAudiobooks => 'Audiolibros propuestos';

  @override
  String get nowPlaying => 'REPRODUCIENDO AHORA';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausar';

  @override
  String get rewind15s => 'Rebobinar 15 segundos';

  @override
  String get forward30s => 'Avanzar 30 segundos';

  @override
  String get previousTrack => 'Pista anterior';

  @override
  String get nextTrack => 'Pista siguiente';

  @override
  String get playbackSpeed => 'Velocidad de reproducción';

  @override
  String get skipSilence => 'Saltar silencio';

  @override
  String get volumeBoost => 'Aumento de volumen';

  @override
  String get sleepTimer => 'Temporizador de apagado';

  @override
  String get cancelTimer => 'Cancelar';

  @override
  String get extend5min => '+5 min';

  @override
  String get stopEndOfChapter => 'Fin del capítulo';

  @override
  String get stopEndOfTrack => 'Fin de la pista';

  @override
  String get shakeToExtend => 'Agitar para extender';

  @override
  String get nightAppearance => 'Apariencia nocturna';

  @override
  String get fadeoutVolume => 'Atenuación suave de volumen';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get addBookmark => 'Añadir marcador';

  @override
  String get saveBookmark => 'Guardar marcador';

  @override
  String get bookmarkTitle => 'Título';

  @override
  String get bookmarkNote => 'Notas o cita (opcional)';

  @override
  String get category => 'Categoría';

  @override
  String get categoryNote => 'Nota';

  @override
  String get categoryQuote => 'Cita';

  @override
  String get categoryRevisit => 'Revisitar';

  @override
  String get listeningHistory => 'Historial de escucha';

  @override
  String get totalListeningHours => 'Horas activas totales de escucha';

  @override
  String get recentSessions => 'Sesiones recientes';

  @override
  String get audiobookSettings => 'Ajustes de audiolibros';

  @override
  String get playbackPreferences => 'Preferencias de reproducción';

  @override
  String get autoRewindOnResume => 'Rebobinado automático al reanudar';

  @override
  String get playerAccentColor => 'Color de acento del reproductor';

  @override
  String get errorFolderNotFound => 'La carpeta seleccionada no existe.';

  @override
  String get errorUnsupportedAudio =>
      'Formato de audio no compatible o archivo dañado.';

  @override
  String get permissionStorageRequired =>
      'Se requiere acceso de almacenamiento para leer audiolibros.';

  @override
  String get noAudiobooksFound =>
      'No se encontraron audiolibros en tu biblioteca.';
}
