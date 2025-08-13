import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a property to capture and preserve unmapped RDF triples during lossless mapping.
///
/// This annotation enables lossless RDF mapping by designating a field to store
/// all triples about the current subject that are not explicitly mapped to other
/// properties. This ensures complete round-trip fidelity when converting between
/// RDF and Dart objects.
///
/// The annotated property must be of type `RdfGraph` or a custom type for which
/// an `UnmappedTriplesMapper` implementation is registered in the rdf_mapper registry.
///
/// During deserialization, the field will be populated with any triples that
/// weren't consumed by other `@RdfProperty` annotations. During serialization,
/// these triples will be restored to maintain the complete RDF graph.
///
/// ## Global Unmapped Triples
///
/// When [globalUnmapped] is `true`, the annotation collects unmapped triples from
/// the entire RDF graph instead of just the current subject. This requires a deep
/// deserializer that supports blank node traversal.
///
/// **IMPORTANT**: The [globalUnmapped] flag should only be used on a single top-level
/// class in your application, typically a document-level container such as a Solid
/// WebID/Profile Document. Using this flag on multiple classes or nested objects
/// can lead to duplicate data collection and unexpected behavior.
///
/// ## Examples
///
/// Basic usage (subject-scoped unmapped triples):
/// ```dart
/// @RdfLocalResource()
/// class Person {
///   @RdfProperty(IriTerm.prevalidated("https://example.org/vocab/name"))
///   late final String name;
///
///   @RdfUnmappedTriples()
///   late final RdfGraph unmappedTriples;
/// }
/// ```
///
/// Global usage (entire graph unmapped triples - use only on top-level document):
/// ```dart
/// @RdfGlobalResource(
///   IriTerm.prevalidated("http://xmlns.com/foaf/0.1/PersonalProfileDocument"),
///   IriStrategy("https://example.org/profile/{id}"),
/// )
/// class ProfileDocument {
///   @RdfIriPart("id")
///   final String id;
///
///   @RdfProperty(IriTerm.prevalidated("http://xmlns.com/foaf/0.1/primaryTopic"))
///   final Person primaryTopic;
///
///   /// Captures ALL unmapped triples from the entire document graph
///   @RdfUnmappedTriples(globalUnmapped: true)
///   final RdfGraph globalUnmappedTriples;
/// }
/// ```
class RdfUnmappedTriples implements RdfAnnotation {
  /// Whether to collect unmapped triples from the entire graph instead of just this subject.
  ///
  /// When `true`, requires a deep deserializer that supports blank node traversal.
  /// Should only be used on a single top-level class (e.g., document containers).
  ///
  /// Defaults to `false` for subject-scoped collection.
  final bool globalUnmapped;

  const RdfUnmappedTriples({this.globalUnmapped = false});
}
