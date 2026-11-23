/// The signed-in user as the UI sees it (no Firebase types leak past the data layer).
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  const AppUser({required this.uid, required this.email, this.displayName});

  /// "maya@studio.com" -> "Maya" when no display name is set.
  String get name {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  /// Returns null on success, or a message to show the user.
  Future<String?> signIn({required String email, required String password});
  Future<String?> signUp({required String email, required String password});
  Future<void> signOut();
}
