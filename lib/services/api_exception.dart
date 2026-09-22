class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'Authentication expired';
}
