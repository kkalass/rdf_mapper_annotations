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
/// This generates a mapper constructor that requires a SerializationProvider:
///
/// ```dart
/// final mapper = DocumentMapper<Person>(
///   primaryTopicSerializationProvider:
///     SerializationProvider.iriContextual((IriTerm iri) =>
///       PersonMapper(documentIriProvider: () => iri.iri)),
/// );
/// ```
///
/// ## Generated Code Contract
///
/// When using `ContextualMapping.named("example")`, the generator creates:
///
/// **Constructor Parameter:**
/// ```dart
/// final SerializationProvider<ParentType, T> exampleSerializationProvider;
/// ```
///
/// **Generated Mapper Constructor:**
/// ```dart
/// const DocumentMapper({
///   required SerializationProvider<Document<T>, T>
///       primaryTopicSerializationProvider,
/// }) : _primaryTopicSerializationProvider = primaryTopicSerializationProvider;
/// ```
///
/// **Usage During Serialization:**
/// ```dart
/// serializer: _primaryTopicSerializationProvider.serializer(
///   resource,      // The parent object being serialized
///   subject,       // The parent's IRI or blank node
///   context,       // Full serialization context
/// )
/// ```
///
/// **Usage During Deserialization:**
/// ```dart
/// deserializer: _primaryTopicSerializationProvider.deserializer(
///   subject,       // The parent's IRI or blank node  
///   context,       // Full deserialization context
/// )
/// ```
///
/// The SerializationProvider encapsulates both serializer and deserializer creation
/// based on the parent context, providing a more cohesive API.
class ContextualMapping {
  /// The name identifier for the contextual mapping parameter.
  ///
  /// This name is used to generate parameter names in the mapper constructor:
  /// - `{name}SerializationProvider` - for the SerializationProvider parameter
  final String name;

  const ContextualMapping._(this.name);

  /// Creates a named contextual mapping configuration.
  ///
  /// The [mapperName] will be used to generate parameter names:
  /// - `{mapperName}SerializationProvider`
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
  /// This generates constructor parameter:
  /// - `primaryTopicSerializationProvider`
  const ContextualMapping.named(String mapperName) : this._(mapperName);

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
