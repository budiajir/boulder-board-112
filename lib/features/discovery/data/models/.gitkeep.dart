/// Clean Architecture — Data Layer: Models
///
/// Models extend domain entities with serialization logic
/// (fromJson, toJson, fromMap, toMap) for data source compatibility.
///
/// Example:
/// ```dart
/// class RouteModel extends RouteEntity {
///   RouteModel({...}) : super(...);
///
///   factory RouteModel.fromJson(Map<String, dynamic> json) { ... }
///   Map<String, dynamic> toJson() { ... }
/// }
/// ```
