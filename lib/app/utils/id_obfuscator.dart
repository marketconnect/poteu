// lib/app/utils/id_obfuscator.dart

int confuseId(int input) {
  // final int multiplied = input * 2;
  // final String base9String = multiplied.toRadixString(9);
  // return int.parse(base9String) + 100000;
  return input + 100000;
}
