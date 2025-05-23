import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';
import 'package:rdf_mapper_annotations/src/property/collection.dart';
import 'package:rdf_mapper_annotations/src/resource/global_resource.dart';
import 'package:rdf_mapper_annotations/src/resource/local_resource.dart';
import 'package:rdf_mapper_annotations/src/term/iri.dart';
import 'package:rdf_mapper_annotations/src/term/literal.dart';

/// Maps a Dart class property to an RDF predicate.
///
/// This core annotation defines how properties are serialized to RDF and
/// deserialized to Dart objects. Any property that should participate in
/// RDF serialization must use `@RdfProperty` with a predicate IRI that identifies
/// the relationship in the RDF graph.
///
/// NOTE: Only public properties are supported. Private properties (with underscore prefix)
/// cannot be used with RDF mapping.
///
/// The annotation can be applied to:
/// - **Instance fields**: Compatible with all type-annotated fields (mutable, `final`, and `late`)
/// - **Getters and setters**: Follow these rules:
///   - With `include: true` (default): Requires both getter and setter for full serialization/deserialization
///   - With `include: false` (read-only from RDF): Requires only a setter as the value is only deserialized
///
/// `RdfProperty` handles data conversion in these ways:
///
/// - **Automatic type mapping**:
///   - Standard Dart types (String, int, bool, DateTime, etc.) → RDF literals
///   - Types with annotations (`@RdfIri`, `@RdfLiteral`, `@RdfGlobalResource`, `@RdfLocalResource`)
///     → use their generated mappers
///   - Types with registered mappers → handled according to their registration
///
/// - **Custom mapping overrides**: For specialized cases, specify exactly one of:
///   - `iri`: Converts values to IRI references
///   - `localResource`: Maps nested objects without assigned IRIs (using anonymous identifiers)
///   - `globalResource`: Maps nested objects as resources with their own IRIs
///   - `literal`: Applies custom literal serialization
///
/// - **Default value handling**:
///   - Provides fallbacks when properties are missing during deserialization
///   - Optional compact serialization by excluding properties matching defaults
///   - Enables non-nullable fields to work with potentially missing data
///
/// - **Collection handling**: Lists, Sets and Maps receive special treatment:
///   - Automatically detected based on type
///   - Each item generates a separate triple with the same predicate
///   - Not serialized as RDF Lists (rdf:first/rdf:rest/rdf:nil)
///   - Map collections must use [RdfMapEntry], [RdfMapKey], and [RdfMapValue]
///
///
/// ## Basic Usage
///
/// ```dart
/// // Basic literal properties with default serialization
/// @RdfProperty(SchemaBook.name)
/// final String title;
///
/// // Optional property (nullable type makes it not required during deserialization)
/// @RdfProperty(
///   SchemaBook.author,
///   iri: IriMapping('http://example.org/author/{authorId}')
/// )
/// String? authorId;
///
/// // Property that will be read from RDF but not written back during serialization
/// @RdfProperty(SchemaBook.modified, include: false)
/// DateTime lastModified;
///
/// // A setter that updates the lastModified field internally
/// set updateLastModified(DateTime value) {
///   lastModified = value;
/// }
///
/// // A completely separate property without RDF mapping - no annotation needed
/// bool get isRecentlyModified =>
///   DateTime.now().difference(lastModified).inDays < 7;
///
/// // Non-nullable property with default value (won't cause error if missing)
/// @RdfProperty(SchemaBook.status, defaultValue: 'active')
/// final String status;
///
/// // Property with default that will be included in serialization even if equal to default
/// @RdfProperty(
///   SchemaBook.rating,
///   defaultValue: 0,
///   includeDefaultsInSerialization: true
/// )
/// final int rating;
/// ```
///
/// ## Advanced Mapping Scenarios
///
/// These examples demonstrate how to override the default mapping behavior when needed.
///
/// ### IRI Mapping
/// ```dart
/// // Override: String property value converted to an IRI using a template
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('{baseUri}/profile/{userId}')
/// )
/// final String userId;
/// ```
///
/// In the example above:
/// - `{userId}` is a property-specific placeholder that refers directly to the property's value
/// - `{baseUri}` is a context variable that must be provided through one of two methods:
///   1. Via a global provider function in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`)
///      The generator will automatically add a required parameter to `initRdfMapper`.
///   2. Via another property in the same class annotated with `@RdfProvides('baseUri')`
///      This is preferred for context variables that are already available in the class.
///
/// For instance, if `userId` contains "jsmith", and `baseUri` resolves to "https://example.com",
/// this will generate an IRI: "https://example.com/profile/jsmith"
///
/// ### Local Resource (Anonymous Resource) Mapping
/// ```dart
/// // Automatic: Person class is already annotated with @RdfLocalResource or implemented and registered manually
/// @RdfProperty(SchemaBook.author)
/// final Person author;
///
/// // Override: Use custom mapper for this specific relationship
/// @RdfProperty(
///   SchemaBook.publisher,
///   localResource: LocalResourceMapping.namedMapper('customPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
///
/// ### Global Resource Mapping
/// ```dart
/// // Automatic: Organization class is already annotated with @RdfGlobalResource or implemented and registered manually
/// @RdfProperty(SchemaBook.publisher)
/// final Organization publisher;
///
/// // Override: Use custom mapper for this specific relationship
/// @RdfProperty(
///   SchemaBook.publisher,
///   globalResource: GlobalResourceMapping.namedMapper('specialPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
///
/// ### Custom Literal Serialization
/// ```dart
/// // Override: Use custom serialization for a property with special formatting needs
/// @RdfProperty(
///   SchemaBook.price,
///   literal: LiteralMapping.namedMapper('priceMapper')
/// )
/// final Price price;
/// ```
///
/// ### Collection Handling
/// ```dart
/// // Default behavior: Automatically handles each collection item separately
/// @RdfProperty(SchemaBook.author)
/// final Iterable<Person> authors; // Each Person is fully mapped with its own set of triples
///
/// // Override: Force a collection to be treated as a single value
/// @RdfProperty(
///   SchemaBook.keywords,
///   collection: RdfCollectionType.none,
///   literal: LiteralMapping.mapperInstance(const StringListMapper())
/// )
/// final List<String> tags;
/// ```
class RdfProperty implements RdfAnnotation {
  /// The RDF predicate (IRI) for this property, e.g., `SchemaBook.name`.
  final IriTerm predicate;

  /// Whether to include this property during serialization to RDF.
  ///
  /// If `false`, the property will be read during deserialization but skipped when generating RDF output.
  /// This creates a one-way mapping (read-only from RDF perspective). This is useful for properties that
  /// should be loaded from RDF but then managed internally by your application logic without writing changes
  /// back to RDF. Defaults to `true`.
  final bool include;

  /// Optional default value for this property.
  ///
  /// When provided for non-nullable properties, this value will be used if the property
  /// is missing in the RDF data during deserialization, avoiding errors.
  ///
  /// During serialization, properties with values equal to their default may be omitted
  /// (controlled by [includeDefaultsInSerialization]).
  ///
  /// Note: Due to Dart's annotation constraints, only constant values can be used. This
  /// works well for primitive types and objects with const constructors.
  final dynamic defaultValue;

  /// Whether to include properties with default values during serialization.
  ///
  /// When `true`, properties with values equal to their default will still be
  /// included in the RDF output.
  ///
  /// When `false` (default), properties with values equal to their default will be
  /// omitted from serialization, resulting in a more compact RDF representation.
  final bool includeDefaultsInSerialization;

  /// Specifies how to treat the property's value as an IRI reference.
  ///
  /// Use this when the property's value represents an IRI (e.g., a URL) or when
  /// you need to override the default literal mapping for a type.
  ///
  /// Only needed when there is no IriMapper already registered globally for the
  /// property value's type, or when you need to override the standard mapping behavior
  /// for this specific property.
  ///
  /// This parameter customizes how property values are converted to IRIs, enabling:
  /// - IRI templates with placeholders (e.g., converting a username to a complete URI)
  /// - Custom mappers for specialized IRI conversion
  /// - Context-dependent IRI construction strategies
  ///
  /// Available IriMapping constructor variants:
  /// - Template constructor: `iri: IriMapping('{baseUri}/profile/{propertyName}')`
  /// - `.namedMapper()` - references a mapper provided to `initRdfMapper`
  /// - `.mapper()` - uses a mapper type that will be instantiated
  /// - `.mapperInstance()` - uses a specific mapper instance
  ///
  /// Template placeholders are resolved in two ways:
  /// 1. Property placeholders (e.g., `{userId}`) use the property's value directly
  /// 2. Context variables (e.g., `{baseUri}`) are provided through:
  ///    - Global provider functions in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`)
  ///    - Properties in the same class annotated with `@RdfProvides('baseUri')`
  ///
  /// Example:
  /// ```dart
  /// // Context variable provided by another property
  /// @RdfProvides('baseUri')
  /// final String serviceUrl = 'https://example.com';
  ///
  /// // Using an IRI template for a property
  /// @RdfProperty(
  ///   Dcterms.creator,
  ///   iri: IriMapping('{baseUri}/profile/{userId}')
  /// )
  /// final String userId; // Converts to "https://example.com/profile/jsmith" if userId="jsmith"
  /// ```
  final IriMapping? iri;

  /// Specifies how to treat the property's value as a nested anonymous resource.
  ///
  /// Use this when the property represents a nested object that shouldn't have its own
  /// persistent identifier (IRI). The object will be serialized as a set of triples
  /// with an anonymous identifier (internally implemented as an RDF blank node).
  ///
  /// Only needed when there is no LocalResourceMapper already registered globally for the
  /// property value's type, or when you need to override the standard mapping behavior for
  /// this specific relationship.
  final LocalResourceMapping? localResource;

  /// Specifies custom literal conversion for the property value.
  ///
  /// Use this parameter when a property requires specialized literal serialization
  /// different from the standard mapping behavior, such as custom formatting,
  /// language tags, or datatype handling.
  ///
  /// Only needed when there is no LiteralMapper already registered globally for the
  /// property value's type, or when you need to override the standard literal conversion
  /// for this specific property.
  ///
  /// This provides property-specific literal conversion rules, useful when:
  /// - Different serialization rules are needed for the same type in different contexts
  /// - A property requires special datatype handling or language tags
  /// - You need specialized formatting for a specific property
  ///
  /// Available LiteralMapping constructor variants:
  /// - `.namedMapper()` - reference a mapper provided to `initRdfMapper`
  /// - `.mapper()` - use a mapper type that will be instantiated
  /// - `.mapperInstance()` - use a specific mapper instance
  /// - `.withLanguage()` - add a language tag to string literals (e.g., "text"@en)
  /// - `.withType()` - specify a custom RDF datatype for the literal
  ///
  /// Examples:
  /// ```dart
  /// // Using a custom literal mapper for a property
  /// @RdfProperty(
  ///   SchemaBook.price,
  ///   literal: LiteralMapping.namedMapper('currencyMapper')
  /// )
  /// final Price price; // Serialized using the custom 'currencyMapper'
  ///
  /// // Adding a language tag to a string property
  /// @RdfProperty(
  ///   SchemaBook.description,
  ///   literal: LiteralMapping.withLanguage('en')
  /// )
  /// final String description; // Serialized as "description"@en
  ///
  /// // Specifying a custom datatype
  /// @RdfProperty(
  ///   SchemaBook.publicationDate,
  ///   literal: LiteralMapping.withType(Xsd.date)
  /// )
  /// final String date; // Serialized with a specific datatype
  /// ```
  final LiteralMapping? literal;

  /// Specifies how to treat the property's value as an RDF resource with its own IRI.
  ///
  /// Use this when the property represents a nested resource that should have its own
  /// globally unique IRI, or to override default mapping behavior for this relationship.
  ///
  /// Only needed when there is no GlobalResourceMapper already registered globally for the
  /// property value's type, or when you need a specific mapper for this relationship that
  /// differs from the standard global resource mapping.
  ///
  /// This parameter can override globally registered mappers for the same type,
  /// allowing relationship-specific mapping while maintaining standard mapping elsewhere:
  ///
  /// ```dart
  /// class Book {
  ///   // Uses custom mapper for this specific relationship
  ///   @RdfProperty(
  ///     SchemaBook.publisher,
  ///     globalResource: GlobalResourceMapping.namedMapper('customPublisherMapper')
  ///   )
  ///   final Publisher publisher;
  ///
  ///   // Uses the globally registered mapper for Publisher
  ///   @RdfProperty(SchemaBook.recommendedBy)
  ///   final Publisher recommendedBy;
  /// }
  /// ```
  ///
  /// Available GlobalResourceMapping constructor variants:
  /// - `.namedMapper()` - references a mapper provided to `initRdfMapper`
  /// - `.mapper()` - uses a mapper type that will be instantiated
  /// - `.mapperInstance()` - uses a specific mapper instance
  final GlobalResourceMapping? globalResource;

  /// Controls how collection properties are serialized to RDF.
  ///
  /// This parameter guides the serialization and deserialization of
  /// collections like `List`, `Set`, and `Map`.
  ///
  /// IMPORTANT: By default, collections are serialized as multiple separate triples
  /// with the same predicate, NOT as RDF Collection structures (rdf:first/rdf:rest/rdf:nil).
  /// This means:
  ///
  /// - List order is not preserved in the RDF representation
  /// - Each item generates its own triple with the same subject and predicate
  /// - Duplicate values may be lost during round-trips if a `Set` is used for deserialization
  ///   (since Sets don't allow duplicates, unlike Lists)
  ///
  /// Consider using `Iterable<T>` instead
  /// of `List<T>` as the property type. This makes it clearer to consumers of your code
  /// that they should not rely on any specific order being maintained after deserialization.
  ///
  /// The mapping configurations (iri, literal, globalResource, localResource) apply
  /// to the item type for collections. For Lists and Sets, this means the element type;
  /// for Maps, it applies to the MapEntry&lt;K,V&gt; type. This allows direct handling of
  /// collections without additional annotations in many cases.
  ///
  /// For `Map` collections, you have two approaches:
  ///
  /// 1. **Direct mapping with configurations**: Provide mapping configurations that work
  ///    directly with MapEntry&lt;K,V&gt;. This is useful for simple key-value pairs or when using
  ///    a custom mapper that handles the MapEntry type directly:
  ///    ```dart
  ///    // Using a custom literal mapper for language-tagged text
  ///    @RdfProperty(
  ///      SchemaBook.title,
  ///      literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper())
  ///    )
  ///    final Map<String, String> translations; // Keys are language codes
  ///    ```
  ///
  /// 2. **Structured mapping with annotations**: For complex map entries, use the [RdfMapEntry]
  ///    annotation on the property along with [RdfMapKey] and [RdfMapValue] annotations in the
  ///    entry class to define the key-value structure.
  ///
  /// Available collection types:
  /// - `auto`: Default - automatically handles collections based on Dart type,
  ///   creating multiple triples with the same predicate
  /// - `none`: Treats a collection as a single value, even for List or Set types
  ///
  /// Example with default auto collection handling:
  /// ```dart
  /// @RdfProperty(SchemaBook.author)
  /// final Iterable<Person> authors; // Each Person becomes a separate triple
  /// ```
  ///
  /// Example treating a collection as a single value with a concrete mapper:
  /// ```dart
  /// // First, create a mapper that handles the conversion between List<String> and a single string literal
  /// class StringListMapper implements LiteralTermMapper<List<String>> {
  ///   const StringListMapper();
  ///
  ///   @override
  ///   List<String> fromRdfTerm(LiteralTerm term, DeserializationContext context) =>
  ///       term.value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  ///
  ///   @override
  ///   LiteralTerm toRdfTerm(List<String> value, SerializationContext context) =>
  ///       LiteralTerm(value.join(', '));
  /// }
  ///
  /// // Then use it with RdfCollectionType.none to treat the list as a single value
  /// @RdfProperty(
  ///   SchemaBook.keywords,
  ///   collection: RdfCollectionType.none,
  ///   literal: LiteralMapping.mapperInstance(const StringListMapper())
  /// )
  /// final List<String> tags; // Generates one triple with comma-separated values: "tag1, tag2, tag3"
  /// ```
  ///
  /// Example using a Map with direct mapping:
  /// ```dart
  /// // A custom mapper that handles language-tagged literals directly
  /// class LocalizedEntryMapper implements LiteralTermMapper<MapEntry<String, String>> {
  ///   const LocalizedEntryMapper();
  ///
  ///   @override
  ///   MapEntry<String, String> fromRdfTerm(LiteralTerm term, DeserializationContext context) =>
  ///       MapEntry(term.language ?? 'en', term.value);
  ///
  ///   @override
  ///   LiteralTerm toRdfTerm(MapEntry<String, String> value, SerializationContext context) =>
  ///       LiteralTerm.withLanguage(value.value, value.key);
  /// }
  ///
  /// // Using the direct mapping approach
  /// @RdfProperty(
  ///   SchemaBook.title,
  ///   literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper())
  /// )
  /// final Map<String, String> translations; // Will generate literals with language tags
  /// ```
  ///
  /// Example using a Map collection with [RdfMapEntry] for more complex structures:
  /// ```dart
  /// // First define a resource class for map entries
  /// @RdfLocalResource() // This class will be serialized as a resource (blank node)
  /// class ConfigSetting {
  ///   @RdfProperty(ExampleVocab.settingKey)
  ///   @RdfMapKey() // Marks this property as the key in the map
  ///   final String key;
  ///
  ///   @RdfProperty(ExampleVocab.settingValue)
  ///   @RdfMapValue() // Marks this property as the value in the map
  ///   final String value;
  ///
  ///   ConfigSetting(this.key, this.value);
  /// }
  ///
  /// // Then use the Map property in your class with the @RdfMapEntry annotation
  /// class ApplicationConfig {
  ///   @RdfProperty(ExampleVocab.settings)
  ///   @RdfMapEntry(ConfigSetting) // Specifies the entry class for this map
  ///   final Map<String, String> settings; // Maps to a collection of ConfigSetting resources
  ///
  ///   ApplicationConfig(this.settings);
  /// }
  /// ```
  ///
  /// Use this parameter when:
  /// - Overriding automatic collection detection
  /// - Controlling whether values are serialized individually or as one unit
  /// - Working with collections that need specific serialization for compatibility
  final RdfCollectionType collection;

  /// Creates an RDF property mapping annotation.
  ///
  /// [predicate] - The RDF predicate IRI that identifies this property in the graph,
  /// typically from a vocabulary constant (e.g., `SchemaBook.name`, `Dcterms.creator`).
  ///
  /// [include] - Controls serialization behavior. When false, creates a one-way mapping
  /// where the property is read from RDF during deserialization but not written back
  /// during serialization. Useful for properties managed internally after loading.
  ///
  /// [defaultValue] - Fallback value for properties missing during deserialization.
  /// Critical for non-nullable properties. Without a default, non-nullable properties
  /// will throw an error if missing from RDF data.
  ///
  /// [includeDefaultsInSerialization] - When true, includes properties even if they
  /// match their default value. When false (default), omits them for more compact RDF.
  ///
  /// Advanced mapping parameters (specify at most one):
  /// - [iri] - Treats property value as an IRI reference
  /// - [localResource] - Treats property as a nested anonymous resource
  /// - [literal] - Applies custom literal serialization
  /// - [globalResource] - Treats property as a resource with its own IRI
  ///
  /// Most properties work with automatic type-based mapping without these advanced
  /// parameters. Only use them to override default behavior for specific cases.
  ///
  /// [collection] - Controls how collection types (List, Set, Map) are serialized.
  const RdfProperty(
    this.predicate, {
    this.include = true,
    this.defaultValue,
    this.includeDefaultsInSerialization = false,
    this.iri,
    this.localResource,
    this.literal,
    this.globalResource,
    this.collection = RdfCollectionType.auto,
  });
}
