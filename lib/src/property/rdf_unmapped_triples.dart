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
/// Example:
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
class RdfUnmappedTriples implements RdfAnnotation {
  const RdfUnmappedTriples();
}
