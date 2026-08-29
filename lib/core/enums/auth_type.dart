enum AuthType {
  email('email', 'Email'),
  phone('phone', 'Phone'),
  google('google', 'Google');

  final String value;
  final String displayName;

  const AuthType(this.value, this.displayName);

  static AuthType fromString(String type) {
    return AuthType.values.firstWhere(
      (e) => e.value == type.toLowerCase(),
      orElse: () => AuthType.email,
    );
  }
}
