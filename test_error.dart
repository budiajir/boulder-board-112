void main() {
  try {
    List.from(null as dynamic);
  } catch (e) {
    print('List.from(null): $e');
  }
  
  try {
    [...null as dynamic];
  } catch (e) {
    print('[...null]: $e');
  }

  try {
    for (var x in null as dynamic) {}
  } catch (e) {
    print('for-in null: $e');
  }
}
