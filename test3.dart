void main() {
  var json = {'holds': null};
  try {
    var res = (json['holds'] as Iterable<dynamic>?)?.map((e) => e).toList() ?? [];
    print('Iterable works: $res');
  } catch(e) {
    print('Iterable failed: $e');
  }

  try {
    var list = json['holds'] as List<dynamic>;
  } catch(e) {
    print('List cast: $e');
  }
}
