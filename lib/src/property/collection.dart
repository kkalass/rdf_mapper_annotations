import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Specifies how Dart collection properties are represented in the RDF graph.
///
/// This enum determines the serialization strategy for collection types (List, Set, Map, etc.)
/// when mapping between Dart objects and RDF triples.
///
/// IMPORTANT NOTE: By default, this library represents Dart collections (List, Set, etc.)
/// as multiple RDF triples with the same subject and predicate, but different objects.
/// This is NOT the same as the RDF Collection concept (rdf:List with rdf:first/rdf:rest/rdf:nil),
/// which requires specific handling to maintain order.
///
/// For Map collections, you have two options:
/// - Provide a mapper for `MapEntry&lt;K,V&gt;` instances directly in the `@RdfProperty` annotation (as iri, literal, localResource or globalResource).
/// - Use the dedicated annotations for complex map entries:
///   - [RdfMapEntry] - Defines the class that represents a map entry
///   - [RdfMapKey] - Marks a property as the key in a map entry
///   - [RdfMapValue] - Marks a property as the value in a map entry
enum RdfCollectionType {
  /// Automatically determines the appropriate collection representation based on the Dart property type.
  ///
  /// This default option intelligently analyzes the property type:
  /// - For `Iterable` types (List, Set, etc.): Creates multiple triples sharing the same subject and predicate.
  ///   Each item produces a separate triple with the same predicate. For example:
  ///   ```
  ///   <subject> <predicate> "item1" .
  ///   <subject> <predicate> "item2" .
  ///   <subject> <predicate> "item3" .
  ///   ```
  ///   For complex objects, each item is fully serialized as a separate resource in the RDF graph.
  ///
  ///   Note: This is NOT an rdf:List (which would use rdf:first/rdf:rest/rdf:nil).
  ///   Order is not guaranteed to be preserved in the RDF serialization.
  ///
  /// - For `Map` types: Creates a collection of triples with the same subject and predicate.
  ///   Each map entry is processed according to available mapping configurations:
  ///   - If `@RdfProperty` includes a mapper that handles `MapEntry&lt;K,V&gt;` directly (e.g.,
  ///     through `literal`, `iri`, etc.), that mapper is used without requiring additional annotations.
  ///   - Otherwise, each entry is serialized as a separate resource in the RDF graph, using either
  ///     [RdfMapKey], [RdfMapValue], and [RdfMapEntry] annotations or standard registered mappers for `MapEntry` (if any).
  ///
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
/// This annotation must be used together with `@RdfMapEntry` when mapping to a Dart `Map`.
/// Within the item class specified by `@RdfMapEntry`, the property annotated with `@RdfMapKey`
/// will be used as the key in the resulting Map. Unlike `@RdfMapValue`, this annotation
/// must always be applied to a property, not a class.
///
/// This annotation is an essential part of the RDF Map mapping system, enabling
/// the mapper to correctly serialize and deserialize complex data structures like Maps.
/// Each map entry is serialized as a distinct resource in the RDF graph, with the annotated
/// property serving as the key. This establishes the necessary key-value relationships
/// between Dart Map types and their RDF graph representation.
///
/// Example:
/// ```dart
/// @RdfProperty(VocabTerm.vectorClock)
/// @RdfMapEntry(VectorClockEntry) // Item class with key and value annotations
/// late Map<String, int> vectorClock;
///
/// // The item class that defines the structure of map entries:
/// @RdfLocalResource(IriTerm('http://example.org/vocab/VectorClockEntry'))
/// class VectorClockEntry {
///   @RdfProperty(IriTerm('http://example.org/vocab/clientId'))
///   @RdfMapKey() // This property becomes the map key
///   final String clientId;
///
///   @RdfProperty(IriTerm('http://example.org/vocab/clockValue'))
///   @RdfMapValue() // This property becomes the map value
///   final int clockValue;
///
///   VectorClockEntry(this.clientId, this.clockValue);
/// }
/// ```
class RdfMapKey extends RdfAnnotation {
  const RdfMapKey();
}

/// Designates a property or class as the value in a mapped `Map<K,V>` collection.
///
/// This annotation works with `@RdfMapEntry` and `@RdfMapKey` to enable proper
/// serialization and deserialization of Map structures in RDF. During serialization,
/// each map entry is fully serialized as a separate resource in the RDF graph.
///
/// The RDF mapper needs to know both the key and value of each Map entry. Since RDF
/// has no native concept of key-value pairs, we need to explicitly mark which
/// properties or classes represent the key and value components in the RDF representation.
///
/// There are two valid ways to use the RDF Map annotations to model a Map&lt;K,V&gt;:
///
/// 1. Property-level annotations - one property as key, one property as value:
/// ```dart
/// @RdfLocalResource()
/// class CounterEntry {
///   @RdfProperty(ExampleVocab.key)
///   @RdfMapKey() // Marks this property as the key
///   final String key;
///
///   @RdfProperty(ExampleVocab.count)
///   @RdfMapValue() // Marks this property as the value
///   final int count;
///
///   CounterEntry(this.key, this.count);
/// }
///
/// @RdfLocalResource()
/// class Counters {
///   @RdfProperty(ExampleVocab.counters)
///   @RdfMapEntry(CounterEntry)
///   final Map<String, int> counts; // Keys and values are extracted from CounterEntry
///
///   Counters(this.counts);
/// }
/// ```
///
/// In this approach, both the key and value are individual properties that are
/// specifically marked. The Map's generic type parameters must match the types
/// of these properties (e.g., Map&lt;String, int&gt;). There must not be any
/// additional properties in the `CounterEntry` class except for computed/derived ones.
/// Key and Value properties must be sufficient for full serialization.
///
/// 2. Class-level annotation - entire entry class represents the value:
/// ```dart
/// // The class with @RdfMapValue at class level
/// @RdfMapValue() // Class-level annotation - the whole class represents a value
/// @RdfLocalResource()
/// class SettingsEntry {
///   // When @RdfMapValue is used at class level, @RdfMapKey can be on a derived property
///   // that doesn't need to be an RDF property itself. It is perfectly fine
///   // to use it on an @RdfProperty, though.
///   @RdfMapKey() // The key property - can be computed/derived
///   String get key => id; // This is a derived property used as a map key
///
///   // The actual RDF property that stores the identifier
///   @RdfProperty(ExampleVocab.settingId)
///   final String id;
///
///   // Multiple RDF properties can be part of the value
///   @RdfProperty(ExampleVocab.settingPriority)
///   final int priority;
///
///   @RdfProperty(ExampleVocab.settingEnabled)
///   final bool enabled;
///
///   @RdfProperty(ExampleVocab.settingDescription)
///   final String description;
///
///   // No @RdfMapValue needed on any property since the class itself
///   // is annotated with @RdfMapValue
///   SettingsEntry(this.id, this.priority, this.enabled, this.description);
/// }
///
/// // In your Resource class:
/// @RdfLocalResource()
/// class Settings {
///   @RdfProperty(ExampleVocab.settings)
///   @RdfMapEntry(SettingsEntry) // Using the class with class-level @RdfMapValue
///   Map<String, SettingsEntry> allSettings; // Key is String, value is the whole SettingsEntry
///
///   Settings(this.allSettings);
/// }
/// ```
///
/// This second approach is particularly useful when the value needs to be a complex object
/// with multiple properties. The entire object becomes the value in the Map, with one of its
/// properties designated as the key. When using class-level `@RdfMapValue`, the property marked
/// with `@RdfMapKey` can be a derived Dart property (getter) that doesn't necessarily map to
/// an RDF property itself.
///
/// You can have as many @RdfProperty properties in the class with this approach as you want, but all
/// other properties must be computed/derived properties that don't need serialization.
class RdfMapValue extends RdfAnnotation {
  const RdfMapValue();
}

/// Specifies the Dart [Type] that represents each entry in a Map.
///
/// This annotation is specifically designed for `Map` collection properties when a
/// custom structure is needed for key-value pairs in RDF. It's important to note that
/// there are multiple ways to handle Map collections in RDF:
///
/// 1. **Using standard mapping configurations without RdfMapEntry**:
///    Maps are treated as collections of MapEntry instances. If you provide
///    mapping configurations (iri, literal, globalResource, localResource)
///    in your @RdfProperty that work with MapEntry&lt;K,V&gt; and the correct generic
///    type parameters, no RdfMapEntry annotation is required.
///
///    Example with literal mapper for language-tagged strings:
///    ```dart
///    @RdfProperty(
///      IriTerm.prevalidated('http://example.org/book/title'),
///      literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper())
///    )
///    final Map<String, String> translations; // Key=language code, Value=translated text
///
///    // The mapper handles conversion to/from language-tagged literals
///    class LocalizedEntryMapper implements LiteralTermMapper<MapEntry<String, String>> {
///      const LocalizedEntryMapper();
///
///      @override
///      MapEntry<String, String> fromRdfTerm(LiteralTerm term, DeserializationContext context) =>
///          MapEntry(term.language ?? 'en', term.value);
///
///      @override
///      LiteralTerm toRdfTerm(MapEntry<String, String> value, SerializationContext context) =>
///          LiteralTerm.withLanguage(value.value, value.key);
///    }
///    ```
///    This approach works when standard registered mappers or custom mapping
///    configurations can handle the MapEntry directly.
///
/// 2. **Using @RdfMapEntry with a dedicated entry class**:
///    This approach uses a separate class to represent each entry in the Map. Use this
///    approach when:
///    - Map keys and values require separate RDF predicates for complex structures
///    - Your map entries need to be represented as resources with multiple properties
///
///    When using @RdfMapEntry, each entry in the Map is fully serialized as a separate
///    resource in the RDF graph according to its own RDF mapping annotations.
///
///    IMPORTANT: All properties in the referenced resource class must either be:
///    - Annotated with `@RdfProperty` for serialization to RDF, or
///    - Computed/derived properties that don't need serialization
///
///    Without proper annotations, the full serialization/deserialization roundtrip will fail, as the mapper
///    won't know how to reconstitute the object from RDF data.
///
///    The referenced class structure depends on how you use the map value annotation:
///
/// 1. When using property-level `@RdfMapValue`, the class must have exactly two `@RdfProperty` annotated properties:
/// ```dart
/// // In your Resource class:
/// @RdfProperty(ExampleVocab.counts)
/// @RdfMapEntry(CounterEntry) // Each entry is a CounterEntry
/// final Map<String, int> counts; // Keys and values extracted from CounterEntry
///
/// // The item class with property-level @RdfMapValue.
/// // Note that we do not specify the rdf:type (classIri) in the @RdfLocalResource
/// // annotation here, as type actually is optional and not needed in this case:
/// @RdfLocalResource()
/// class CounterEntry {
///   @RdfProperty(IriTerm('http://example.org/vocab/key'))
///   @RdfMapKey() // This property becomes the map key
///   final String key;
///
///   @RdfProperty(IriTerm('http://example.org/vocab/count'))
///   @RdfMapValue() // This property becomes the map value
///   final int count;
///
///   // With property-level @RdfMapValue, no additional @RdfProperty properties are allowed
///   // You can have derived properties that don't need serialization:
///   bool get isHighValue => count > 1000;
///
///   CounterEntry(this.key, this.count);
/// }
/// ```
///
/// 2. When using class-level `@RdfMapValue`, the class can have multiple `@RdfProperty` annotated properties:
/// ```dart
/// // With class-level @RdfMapValue:
/// @RdfMapValue() // Class-level annotation
/// @RdfLocalResource(ExampleVocab.SettingsEntry)
/// class SettingsEntry {
///   @RdfProperty(ExampleVocab.settingKey)
///   @RdfMapKey() // The key property
///   final String key;
///
///   // Multiple RDF properties can be part of the value
///   @RdfProperty(ExampleVocab.settingPriority)
///   final int priority;
///
///   @RdfProperty(ExampleVocab.settingEnabled)
///   final bool enabled;
///
///   @RdfProperty(ExampleVocab.settingTimestamp)
///   final DateTime timestamp;
///
///   // Derived properties are also allowed
///   bool get isRecent => DateTime.now().difference(timestamp).inDays < 7;
///
///   SettingsEntry(this.key, this.priority, this.enabled, this.timestamp);
/// }
/// ```
class RdfMapEntry extends RdfAnnotation {
  /// The Dart [Type] that defines the structure for each entry in the Map.
  ///
  /// For Maps, this class should contain properties annotated with
  /// [RdfMapKey] and [RdfMapValue] to define the mapping structure.
  ///
  /// When serialized to RDF, each instance of this class becomes a separate resource
  /// in the RDF graph, with all of its RDF-annotated properties properly serialized.
  final Type itemClass;

  /// Creates a new RdfMapEntry annotation with the specified item class.
  ///
  /// The [itemClass] parameter defines the type used for mapping Map entries.
  const RdfMapEntry(this.itemClass);
}
