/// Configuration for contextual property mapping.
///
/// Contextual mapping allows a property's serializer and deserializer
/// to access the parent object, parent subject, and full context during
/// RDF serialization and deserialization operations.
///
/// This enables complex scenarios where property mapping depends on:
/// - Parent object state and other properties
/// - Parent resource's IRI or blank node identifier
/// - Full serialization/deserialization context
///
/// Common use cases include:
/// - Computing dependent object IRIs based on parent properties
/// - Creating nested resources that reference their container
/// - Context-dependent mapping strategies
/// - Cross-property validation during deserialization
///
/// ## Usage
///
/// Use contextual mapping by specifying it in the `@RdfProperty` annotation:
///
/// ```dart
/// class Document<T> {
///   @RdfProperty(FoafDocument.primaryTopic)
///   final String documentIri;
///
///   @RdfProperty(
///     FoafDocument.primaryTopic,
///     contextual: ContextualMapping.named("primaryTopic")
///   )
///   final T primaryTopic;
/// }
/// ```
///
/// This generates a mapper constructor that requires contextual factory functions:
///
/// ```dart
/// final mapper = DocumentMapper<Person>(
///   primaryTopicContextualSerializer: (parent, parentSubject, context) =>
///     PersonMapper(documentIriProvider: () => parentSubject.iri),
///   primaryTopicContextualDeserializer: (parentSubject, context) =>
///     PersonMapper(documentIriProvider: () => parentSubject.iri),
/// );
/// ```
///
/// ## Generated Code Contract
///
/// When using `ContextualMapping.named("example")`, the generator creates:
///
/// **Serializer Factory Function:**
/// ```dart
/// final Serializer<T> Function(
///   ParentType parent,        // The parent object being serialized
///   SubjectType parentSubject, // IriTerm for global resources, BlankNodeTerm for local resources
///   SerializationContext context // Full serialization context
/// ) exampleContextualSerializer;
/// ```
///
/// **Deserializer Factory Function:**
/// ```dart
/// final Deserializer<T> Function(
///   SubjectType parentSubject, // IriTerm for global resources, BlankNodeTerm for local resources
///   DeserializationContext context // Full deserialization context
/// ) exampleContextualDeserializer;
/// ```
///
/// The factory functions are called during serialization/deserialization to obtain
/// the appropriate serializer/deserializer for the current context.
class ContextualMapping {
  /// The name identifier for the contextual mapping parameter.
  ///
  /// This name is used to generate parameter names in the mapper constructor:
  /// - `{name}ContextualSerializer` - for the serializer factory function
  /// - `{name}ContextualDeserializer` - for the deserializer factory function
  final String name;

  const ContextualMapping._(this.name);

  /// Creates a named contextual mapping configuration.
  ///
  /// The [mapperName] will be used to generate parameter names:
  /// - `{mapperName}ContextualSerializer`
  /// - `{mapperName}ContextualDeserializer`
  ///
  /// Example:
  /// ```dart
  /// @RdfProperty(
  ///   FoafDocument.primaryTopic,
  ///   contextual: ContextualMapping.named("primaryTopic")
  /// )
  /// final T primaryTopic;
  /// ```
  ///
  /// This generates constructor parameters:
  /// - `primaryTopicContextualSerializer`
  /// - `primaryTopicContextualDeserializer`
  static ContextualMapping named(String mapperName) =>
      ContextualMapping._(mapperName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextualMapping &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'ContextualMapping.named("$name")';
}
