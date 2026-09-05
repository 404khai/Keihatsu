import 'history_repository.dart';
import 'library_repository.dart';

class SessionBootstrapService {
  final LibraryRepository libraryRepository;
  final HistoryRepository historyRepository;

  String? _activeUserId;
  Future<void>? _inFlight;

  SessionBootstrapService({
    required this.libraryRepository,
    required this.historyRepository,
  });

  Future<void> bootstrapUserData({
    required String token,
    required String userId,
    bool force = false,
  }) {
    if (!force && _activeUserId == userId && _inFlight != null) {
      return _inFlight!;
    }

    _activeUserId = userId;
    _inFlight = _runBootstrap(token);
    return _inFlight!;
  }

  Future<void> _runBootstrap(String token) async {
    try {
      await libraryRepository.refreshLibrary(token: token);
      await historyRepository.refreshHistoryFromServer(token);
    } finally {
      _inFlight = null;
    }
  }
}
