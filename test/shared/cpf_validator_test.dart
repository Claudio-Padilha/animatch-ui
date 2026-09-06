import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/shared/utils/cpf_validator.dart';

void main() {
  test('rejects all-same-digit CPFs (the M-5 bug)', () {
    expect(isValidCpf('00000000000'), isFalse);
    expect(isValidCpf('11111111111'), isFalse);
    expect(isValidCpf('99999999999'), isFalse);
  });

  test('rejects wrong length', () {
    expect(isValidCpf('123'), isFalse);
    expect(isValidCpf(''), isFalse);
  });

  test('accepts a known-valid CPF, formatted and raw', () {
    expect(isValidCpf('111.444.777-35'), isTrue);
    expect(isValidCpf('11144477735'), isTrue);
  });

  test('rejects a valid CPF with a tampered digit', () {
    expect(isValidCpf('111.444.777-36'), isFalse); // wrong 2nd check digit
    expect(isValidCpf('111.444.776-35'), isFalse); // wrong body digit
  });

  test('rejects made-up check digits', () {
    expect(isValidCpf('123.456.789-00'), isFalse);
  });
}
