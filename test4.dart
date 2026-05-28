void main() {
  try {
    var x = null as Iterable<dynamic>;
  } catch (e) {
    print('Cast: $e');
  }
}
