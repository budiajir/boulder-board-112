void main() {
  try {
    Map<String, dynamic>.from(null as dynamic);
  } catch (e) {
    print('Map.from(null): $e');
  }
}
