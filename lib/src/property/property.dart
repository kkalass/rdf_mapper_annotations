import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';
import 'package:rdf_mapper_annotations/src/property/collection.dart';
import 'package:rdf_mapper_annotations/src/resource/global_resource.dart';
import 'package:rdf_mapper_annotations/src/resource/local_resource.dart';
import 'package:rdf_mapper_annotations/src/term/iri.dart';
import 'package:rdf_mapper_annotations/src/term/literal.dart';

/// Marks a property to be mapped to/from an RDF predicate.
///
/// This is the core annotation for class properties, defining how they
/// are serialized to RDF and deserialized back to Dart objects. Every property
/// that should be included in RDF serialization must be annotated with
/// `@RdfProperty` and provide a predicate IRI that identifies the relationship
/// in the RDF graph.
///
/// `RdfProperty` works with your data in the following ways:
///
/// - **Automatic mapping**: Properties are automatically mapped based on their type:
///   - Standard Dart types (String, num, bool, DateTime, etc.) are mapped to appropriate RDF literals
///   - Types annotated with `@RdfIri`, `@RdfLiteral`, `@RdfGlobalResource` or `@RdfLocalResource`
///     use their associated generated mappers
///   - Types with mappers registered in the RdfMapper instance are handled according to
///     their registration
///
/// - **Custom mapping**: For specialized cases (like treating a String as an IRI),
///   you can override the default mapping by specifying exactly one of:
///   - `iri`: Convert property values to IRI references
///   - `localResource`: Map nested objects as blank nodes
///   - `globalResource`: Map nested objects as resources with their own IRIs
///   - `literal`: Apply custom serialization rules for literal values
///
/// - **Collections**: Lists, Sets and Maps are detected and handled automatically,
///   with options to customize their serialization behavior
///
///
/// ## Basic Usage
///
/// ```dart
/// // Basic literal properties with default serialization
/// @RdfProperty(SchemaBook.name)
/// final String title;
///
/// // Optional property (not required during deserialization)
/// @RdfProperty(SchemaBook.author, required: false)
/// String? author;
///
/// // Property that won't be included in serialization (read-only)
/// @RdfProperty(SchemaBook.modified, include: false)
/// DateTime get lastModified => _modified;
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
///   iri: IriMapping('{baseUri}/profile/{value}')
/// )
/// final String userId;
/// ```
///
/// ### Local Resource (Blank Node) Mapping
/// ```dart
/// // Automatic: Person class is already annotated with @RdfLocalResource
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
/// // Automatic: Organization class is already annotated with @RdfGlobalResource
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
/// final List<Person> authors; // Each Person is fully mapped with its own set of triples
///
/// // Override: Force a collection to be treated as a single value
/// @RdfProperty(
///   SchemaBook.keywords,
///   collection: RdfCollectionType.none
/// )
/// final List<String> tags;
/// ```
class RdfProperty implements RdfAnnotation {
  /// The RDF predicate (IRI) for this property, e.g., `SchemaBook.name`.
  final IriTerm predicate;

  /// Whether this property is required during deserialization.
  /// If `true` and the property is missing in the RDF, a deserialization error
  /// will occur. Defaults to `true`.
  final bool required;

  /// Whether to include this property during serialization.
  /// If `false`, the property will be skipped when generating RDF. Defaults to `true`.
  final bool include;

  /// Optional specification for treating the property's value as an IRI reference.
  ///
  /// Use this when the property's value itself represents an IRI (e.g., a URL) or when
  /// you want to override the default literal mapping for a type.
  ///
  /// When specified in the RdfProperty, this mapping parameter allows you to customize how the
  /// property value is converted to an IRI. This can be useful for:
  /// - Applying specific IRI templates to property values (e.g., converting a username to a full URI)
  /// - Using custom mappers for IRI conversion in specific contexts
  /// - Implementing different IRI construction strategies based on property location
  ///
  /// You can use any of the IriMapping constructor variants:
  /// - Standard constructor with template: `iri: IriMapping('{baseUri}/profile/{value}')`
  /// - `.namedMapper()` - reference a mapper provided to `initRdfMapper`
  /// - `.mapper()` - use a mapper type that will be instantiated
  /// - `.mapperInstance()` - use a specific mapper instance
  ///
  /// Example:
  /// ```dart
  /// // Using an IRI template for a property
  /// @RdfProperty(
  ///   Dcterms.creator,
  ///   iri: IriMapping('{baseUri}/profile/{value}')
  /// )
  /// final String userId; // Will be converted to an IRI using the template
  /// ```
  final IriMapping? iri;

  /// Optional specification for treating the property's value as a blank node.
  ///
  /// Use this when the property's value is a nested resource that should not
  /// have its own global IRI, or to override the default mapping behavior for this specific property.
  final LocalResourceMapping? localResource;

  /// Optional specification for treating the property's value as a literal with
  /// special handling (e.g., custom serialization/deserialization methods,
  /// language tags).
  ///
  /// Use this parameter when the property's value requires specialized literal serialization
  /// that differs from the standard mapper behavior. It allows you to customize how a property
  /// value is serialized as an RDF literal, independent of how the class is mapped globally.
  ///
  /// When provided as a mapping parameter to RdfProperty, this can provide property-specific
  /// literal conversion rules. This is especially useful when:
  /// - You need different serialization rules for the same type in different contexts
  /// - A property requires special datatype handling or language tags
  /// - You want to use specialized formatting for a specific property value
  ///
  /// You can use any of the RdfLiteral constructor variants:
  /// - Standard constructor: `literal: LiteralMapping()` - automatic conversion based on @RdfValue
  /// - `.custom()` - specify custom conversion methods: `literal: LiteralMapping.custom(...)`
  /// - `.namedMapper()` - reference a mapper provided to `initRdfMapper`
  /// - `.mapper()` - use a mapper type that will be instantiated
  /// - `.mapperInstance()` - use a specific mapper instance
  ///
  /// Example:
  /// ```dart
  /// // Using a custom literal mapper for a property
  /// @RdfProperty(
  ///   SchemaBook.price,
  ///   literal: LiteralMapping.namedMapper('currencyMapper')
  /// )
  /// final Price price; // Will be serialized using the custom 'currencyMapper'
  /// ```
  final LiteralMapping? literal;

  /// Optional specification for treating the property's value as an RDF global resource.
  ///
  /// Use this when the property's value is a nested resource that should have its own
  /// globally unique IRI, or to override the default mapping behavior for this specific relationship.
  ///
  /// When provided as a mapping parameter to RdfProperty, this can override globally registered
  /// mappers for the same type. This allows you to customize how specific instances of a type
  /// are mapped to RDF, while using the global mapper for other instances of the same type elsewhere.
  ///
  /// The primary use case is providing custom mappers for specific relationships:
  ///
  /// ```dart
  /// class Book {
  ///   // This property uses a custom mapper specific to this relationship
  ///   @RdfProperty(
  ///     SchemaBook.publisher,
  ///     globalResource: GlobalResourceMapping.namedMapper('customPublisherMapper')
  ///   )
  ///   final Publisher publisher;
  ///
  ///   // Other Publisher instances elsewhere will still use the globally registered mapper
  ///   @RdfProperty(SchemaBook.recommendedBy)
  ///   final Publisher recommendedBy;
  /// }
  /// ```
  ///
  /// You can use any of the GlobalResourceMapping constructor variants:
  /// - `.namedMapper()` - reference a mapper provided to `initRdfMapper`
  /// - `.mapper()` - use a mapper type that will be instantiated
  /// - `.mapperInstance()` - use a specific mapper instance
  /// - Standard constructor - useful when you need a completely different IRI pattern for specific instances
  final GlobalResourceMapping? globalResource;

  /// Optional specification for collection handling.
  ///
  /// This hint helps the generator understand how to serialize and deserialize
  /// collections (e.g., `List`, `Set`, `Map`).
  ///
  /// Use this parameter to control how the RDF mapper should handle properties that contain
  /// multiple values. By default (with `auto`), the mapper automatically detects collection
  /// types like `List` or `Set` and serializes each element as a separate RDF triple with
  /// the same predicate.
  ///
  /// When to use specific collection types:
  /// - `auto`: Default behavior - automatically detects and handles collections based on Dart type
  /// - `none`: Forces a collection property to be treated as a single value, even if it's a List or Set
  ///
  /// Example with default auto collection handling:
  /// ```dart
  /// @RdfProperty(SchemaBook.author)
  /// final Iterable<Person> authors; // Each Person is a separate resource with its own set of triples
  /// ```
  ///
  /// Example forcing a collection to be treated as a single value:
  /// ```dart
  /// @RdfProperty(
  ///   SchemaBook.keywords,
  ///   collection: RdfCollectionType.none
  ///   literal: LiteralMapping.namedMapper('keywordsMapper')
  /// )
  /// final Iterable<String> tags; // Generates a single triple with the entire list as one value due to the literal mapper named in the annotation
  /// ```
  ///
  /// This parameter is particularly important when:
  /// - You need to override automatic collection detection
  /// - You want to control whether multiple values are serialized individually or as a single unit
  /// - You're working with custom collection types that need specific handling
  final RdfCollectionType collection;

  /// Creates a property annotation that maps a class property to an RDF predicate.
  ///
  /// [predicate] is the RDF predicate IRI that represents this property in the graph,
  /// typically from a vocabulary like `SchemaBook.name` or `Dcterms.creator`.
  ///
  /// [required] determines whether this property must be present during deserialization.
  /// If true (default) and the property is missing in the RDF data, a deserialization error will occur.
  ///
  /// [include] determines whether this property should be included during serialization.
  /// Setting to false makes the property read-only in RDF context.
  ///
  /// Advanced mapping parameters (only one should be specified for a property):
  /// - [iri]: Override to treat the property value as an IRI reference
  /// - [localResource]: Override to treat the property as a nested blank node resource
  /// - [literal]: Override to apply custom literal serialization rules
  /// - [globalResource]: Override to treat the property as a resource with its own IRI
  ///
  /// These advanced parameters are only needed when you want to override the default
  /// mapping behavior for a specific property. For most cases, the automatic mapping
  /// based on property type will work without any additional configuration.
  ///
  /// [collection] controls how collection types (List, Set, Map) are handled.
  const RdfProperty(
    this.predicate, {
    this.required = true,
    this.include = true,
    this.iri,
    this.localResource,
    this.literal,
    this.globalResource,
    this.collection = RdfCollectionType.auto,
  });
}
