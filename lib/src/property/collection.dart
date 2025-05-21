import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Defines how a property should be serialized in the RDF graph.
enum RdfCollectionType {
  /// Automatically determines the appropriate collection representation based on the Dart property type.
  ///
  /// This default option intelligently analyzes the property type:
  /// - For `Iterable` types: Creates a collection of triples sharing the same subject and predicate.
  ///   For complex objects, each item is fully serialized as a separate resource in the RDF graph.
  /// - For `Map` types: Creates a collection of triples with the same subject and predicate, where
  ///   the object is either a BlankNode or an IRI pointing to a resource. Each map entry is serialized
  ///   as a separate resource in the RDF graph. Use with [RdfCollectionKey], [RdfCollectionValue],
  ///   and [RdfCollectionOf] annotations to define how keys and values are mapped from these resources.
  /// - For all other types: Treats as a single value (non-collection).
  auto,

  /// Forces the property to be treated as a single value, even if the Dart type is a collection.
  ///
  /// Use this to explicitly override the automatic collection detection when you need a collection
  /// property to be serialized as a single value in the RDF graph. This gives you full control
  /// over the mapping process in your custom mapper implementation.
  none,
}

/// Designates a property as the key in a mapped `Map<K,V>` collection.
///
/// This annotation must be used together with `@RdfCollectionOf` when mapping to a Dart `Map`.
/// Within the item class specified by `@RdfCollectionOf`, the property annotated with `@RdfCollectionKey`
/// will be used as the key in the resulting Map.
///
/// This annotation is an essential part of the RDF collection mapping system, enabling
/// the mapper to correctly serialize and deserialize complex data structures like Maps.
/// Each map entry is serialized as a distinct resource in the RDF graph, with the annotated
/// property serving as the key. This establishes the necessary key-value relationships
/// between Dart Map types and their RDF graph representation.
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

/// Designates a property as the value in a mapped `Map<K,V>` collection.
///
/// This annotation must be used together with `@RdfCollectionOf` when mapping to a Dart `Map`.
/// Within the item class specified by `@RdfCollectionOf`, the property annotated with `@RdfCollectionValue`
/// will be used as the value in the resulting Map.
///
/// This annotation works in tandem with `@RdfCollectionKey` to facilitate proper
/// serialization and deserialization of Map types in the RDF graph. During serialization,
/// each map entry is fully serialized as a separate resource in the RDF graph, with
/// distinct properties for both the key and value components. Complex nested values
/// are properly serialized according to their own RDF mapping annotations.
///
/// For a complete example, see the documentation for `RdfCollectionKey`.
class RdfCollectionValue extends RdfAnnotation {
  const RdfCollectionValue();
}

/// Specifies the Dart [Type] that represents each item within a collection property.
///
/// This annotation is mandatory for `Map` collection properties, as a `Map` is internally
/// processed as a collection of `MapEntry` objects. This indirection is necessary to properly
/// map the key and value components of each `MapEntry` to their RDF representation.
///
/// For both `Iterable` and `Map` collections, each item is fully serialized as a separate
/// resource in the RDF graph according to its own RDF mapping annotations. This means that
/// complex nested data structures are preserved in the RDF representation.
///
/// In RDF, collections can be modeled in various ways (including RDF Lists, containers, or
/// custom subject-predicate-object patterns). This annotation provides the mapper with crucial
/// information about both the type of items in the collection and their RDF mapping structure,
/// ensuring correct serialization and deserialization according to their RDF mapping annotations.
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
  /// The Dart [Type] that defines the structure for each item in the collection.
  ///
  /// For Map collections, this class should contain properties annotated with
  /// [RdfCollectionKey] and [RdfCollectionValue] to define the mapping structure.
  ///
  /// When serialized to RDF, each instance of this class becomes a separate resource
  /// in the RDF graph, with all of its RDF-annotated properties properly serialized.
  final Type itemClass;

  /// Creates a new RdfCollectionOf annotation with the specified item class.
  ///
  /// The [itemClass] parameter defines the type used for mapping collection items.
  const RdfCollectionOf(this.itemClass);
}
