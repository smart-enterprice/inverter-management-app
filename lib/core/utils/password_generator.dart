import 'dart:math';

/// Generates a secure random password for new dealer accounts.
/// Password is shown once to the admin creating the account.
String generateSecurePassword({int length = 12}) {
  const upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower   = 'abcdefghjkmnpqrstuvwxyz';
  const digits  = '23456789';
  const symbols = '!@#\$%&*';
  const all     = upper + lower + digits + symbols;

  final rng = Random.secure();

  // Guarantee at least one of each required character class
  final chars = [
    upper  [rng.nextInt(upper.length)],
    lower  [rng.nextInt(lower.length)],
    digits [rng.nextInt(digits.length)],
    symbols[rng.nextInt(symbols.length)],
    ...List.generate(length - 4, (_) => all[rng.nextInt(all.length)]),
  ]..shuffle(rng);

  return chars.join();
}