/// Validates a Brazilian CPF using its two check digits.
///
/// Accepts either raw digits or a formatted string (000.000.000-00) —
/// non-digit characters are stripped before validation.
bool isValidCpf(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return false;
  // Rejects 00000000000, 11111111111, ... — these pass a naive length
  // check and would otherwise pass the checksum below too (an all-same-
  // digit input always produces a remainder that maps back to the
  // repeated digit).
  if (RegExp(r'^(\d)\1*$').hasMatch(digits)) return false;

  int checkDigit(String base) {
    var sum = 0;
    final weight = base.length + 1;
    for (var i = 0; i < base.length; i++) {
      sum += int.parse(base[i]) * (weight - i);
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  if (checkDigit(digits.substring(0, 9)) != int.parse(digits[9])) {
    return false;
  }
  if (checkDigit(digits.substring(0, 10)) != int.parse(digits[10])) {
    return false;
  }
  return true;
}
