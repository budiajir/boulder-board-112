void main() {
  dynamic response = null;
  try {
    var res = response.map((x) => x);
  } catch (e) {
    print('Dynamic map: $e');
  }

  try {
    Iterable<dynamic> it = null as dynamic;
    for (var x in it) {}
  } catch (e) {
    print('Iterable iteration: $e');
  }
}
