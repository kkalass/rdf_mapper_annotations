import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// The type of collection to use for RDF property serialization.
enum RdfCollectionType {
  /// Automatically determine collection type from property type.
  ///
  /// This default option analyzes the property type:
  /// - For `Iterable` types, treats as a collection of triples with the same subject and predicate.
  /// - For `Map` types: A collection of triples with the same subject
  ///   and predicate and the object being either a BlankNode or an IRI which
  ///   points to a resource. Use in conjunction with [CollectionKey],
  ///   [CollectionValue] and [CollectionOf] to specify the key and value predicates
  ///   from this resource.
  /// - For other types, treats as a single value
  auto,

  /// Not a collection - treat as a single value even if the Dart type is a
  /// collection.
  ///
  /// Use this to override automatic collection detection when you want a collection
  /// property to be treated as a single value (and thus have full control in your mapper).
  none,
}

/// Marks a property that serves as the key in a mapped `Map<K,V>` collection.
///
/// Used with `@RdfCollectionOf` when mapping to a Dart `Map`. Within the item class
/// specified by `RdfCollectionOf`, the property marked with `@RdfCollectionKey`
/// becomes the key in the resulting Map.
///
/// This annotation is part of the mapping system for collection types, which allows
/// RDF mapper to properly serialize and deserialize complex data structures like
/// Maps. When used correctly, it helps maintain the appropriate key-value
/// relationships between Dart Map types and the underlying RDF representation.
///
/// Example:
/// ```dart
/// @RdfProperty(VocabTerm.vectorClock)
/// @RdfCollectionOf(VectorClockEntry) // Item class with key and value annotations
/// late Map<String, int> vectorClock;
///
/// // The item class that defines the structure of map entries:
/// @RdfLocalResource(IriTerm('http://example.org/vocab/VectorClockEntry'))
/// class VectorClockEntry {
///   @RdfProperty(IriTerm('http://example.org/vocab/clientId'))
///   @RdfCollectionKey() // This property becomes the map key
///   final String clientId;
///
///   @RdfProperty(IriTerm('http://example.org/vocab/clockValue'))
///   @RdfCollectionValue() // This property becomes the map value
///   final int clockValue;
///
///   VectorClockEntry(this.clientId, this.clockValue);
/// }
/// ```
class RdfCollectionKey extends RdfAnnotation {
  const RdfCollectionKey();
}

/// Marks a property that serves as the value in a mapped `Map<K,V>` collection.
///
/// Used with `@RdfCollectionOf` when mapping to a Dart `Map`. Within the item class
/// specified by `RdfCollectionOf`, the property marked with `@RdfCollectionValue`
/// becomes the value in the resulting Map.
///
/// This annotation works together with `@RdfCollectionKey` to enable proper
/// serialization and deserialization of Map types in the RDF graph. Each item in the
/// collection is represented as a separate resource in the RDF graph, with properties
/// for both the key and value components.
///
/// For a complete example, see the documentation for `RdfCollectionKey`.
class RdfCollectionValue extends RdfAnnotation {
  const RdfCollectionValue();
}

/// Specifies the Dart [Type] of the items within a collection property.
///
/// This annotation is required on `Map` collection properties, because
/// a `Map` is treated as a collection of `MapEntry` objects. and we need this
/// indirection to be able to map the key and value properties of the `MapEntry`.
///
/// In RDF, collections can be represented in various ways (such as RDF Lists or
/// subject-predicate-object patterns). This annotation helps the RDF mapper
/// understand not only the type of items in the collection but also how to properly
/// serialize and deserialize them according to their RDF mapping annotations.
///
/// Examples:
/// ```dart
///
/// // In your Resource class:
/// @RdfProperty(ExampleVocab.counts)
/// @RdfCollectionOf(CounterEntry) // Each entry is a CounterEntry
/// final Map<String, int> counts; // Keys and values extracted from CounterEntry
///
/// // The item class that defines the structure of map entries and will be
/// // used to map to RDF, and then to a Dart MapEntry:
/// @RdfLocalResource()
/// class CounterEntry {
///   @RdfProperty(IriTerm('http://example.org/vocab/key'))
///   @RdfCollectionKey() // This property becomes the map key
///   final String key;
///
///   @RdfProperty(IriTerm('http://example.org/vocab/count'))
///   @RdfCollectionValue() // This property becomes the map value
///   final int count;
///
///   CounterEntry(this.key, this.count);
/// }
/// ```
class RdfCollectionOf extends RdfAnnotation {
  /// The Dart [Type] of the class representing each item in the collection.
  final Type itemClass;
  const RdfCollectionOf(this.itemClass);
}
