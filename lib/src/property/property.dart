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
/// `RdfProperty` supports several advanced mapping scenarios through its
/// parameters:
///
/// - **Basic literal mapping**: Simple values like String, num, bool, DateTime are
///   automatically mapped to appropriate RDF literal values. This is also true
///   for all other types that have a registered LiteralTermMapper.
/// - **Nested resources**: Properties that refer to other objects can be mapped as:
///   - *Global resources* with their own IRIs (using `globalResource` parameter)
///   - *Local resources* as blank nodes (using `localResource` parameter)
/// - **Custom IRI mapping**: Property values can be converted to IRIs (using `iri` parameter)
/// - **Custom literal serialization**: Property values can use specialized literal
///   serialization (using `literal` parameter)
/// - **Collections**: Lists, Sets and Maps are handled automatically or can be customized
///
/// **Important:** Only specify one of `iri`, `localResource`, `literal`, or
/// `globalResource` for a property, as they define mutually exclusive
/// mapping strategies.
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
/// ### IRI Mapping
/// ```dart
/// // Property value converted to an IRI using a template
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('{baseUri}/profile/{value}')
/// )
/// final String userId;
/// ```
///
/// ### Local Resource (Blank Node) Mapping
/// ```dart
/// // Nested object as blank node with standard mapper
/// @RdfProperty(SchemaBook.author)
/// final Person author; // Person class must have @RdfLocalResource
///
/// // Nested object with custom mapper specifically for this relationship
/// @RdfProperty(
///   SchemaBook.publisher,
///   localResource: LocalResourceMapping.namedMapper('customPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
///
/// ### Global Resource Mapping
/// ```dart
/// // Reference to another resource with its own IRI
/// @RdfProperty(SchemaBook.publisher)
/// final Organization publisher; // Organization must have @RdfGlobalResource
///
/// // With custom mapper override for this specific relationship
/// @RdfProperty(
///   SchemaBook.publisher,
///   globalResource: GlobalResourceMapping.namedMapper('specialPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
///
/// ### Custom Literal Serialization
/// ```dart
/// // Custom serialization for a property with special formatting needs
/// @RdfProperty(
///   SchemaBook.price,
///   literal: LiteralMapping.namedMapper('priceMapper')
/// )
/// final Price price;
/// ```
///
/// ### Collection Handling
/// ```dart
/// // Automatically handled as multiple triples (one per item)
/// @RdfProperty(SchemaBook.author)
/// final List<Person> authors;
///
/// // Force a collection to be treated as a single value
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
  /// Use this when the property's value itself represents an IRI (e.g., a URL).
  ///
  /// When specified at the property level, this annotation allows you to customize how the
  /// property value is converted to an IRI. This can be useful for:
  /// - Applying specific IRI templates to property values
  /// - Using custom mappers for IRI conversion in specific contexts
  /// - Implementing different IRI construction strategies based on property location
  ///
  /// You can use any of the RdfIri constructor variants:
  /// - Standard constructor with template: `iri: RdfIri('prefix:{value}')`
  /// - Standard constructor without template: `iri: RdfIri()`
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
  /// have its own global IRI.
  final LocalResourceMapping? localResource;

  /// Optional specification for treating the property's value as a literal with
  /// special handling (e.g., custom serialization/deserialization methods,
  /// language tags).
  ///
  /// Use this parameter when the property's value requires specialized literal serialization
  /// that differs from the standard mapper behavior. It allows you to customize how a property
  /// value is serialized as an RDF literal, independent of how the class is mapped globally.
  ///
  /// When specified at the property level, this annotation can provide property-specific
  /// literal conversion rules. This is especially useful when:
  /// - You need different serialization rules for the same type in different contexts
  /// - A property requires special datatype handling or language tags
  /// - You want to use specialized formatting for a specific property value
  ///
  /// You can use any of the RdfLiteral constructor variants:
  /// - Standard constructor: `literal: RdfLiteral()` - automatic conversion based on @RdfValue
  /// - `.custom()` - specify custom conversion methods: `literal: RdfLiteral.custom(...)`
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
  /// Use this when the property's value is a nested resource that has its own
  /// globally unique IRI.
  ///
  /// When specified at the property level, this annotation can override globally registered
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
  /// You can use any of the RdfGlobalResource constructor variants:
  /// - `.namedMapper()` - reference a mapper provided to `initRdfMapper`
  /// - `.mapper()` - use a mapper type that will be instantiated
  /// - `.mapperInstance()` - use a specific mapper instance
  /// - Standard constructor - usefull when you need a completely different IRI pattern for specific instances
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
  /// final List<Person> authors; // Generates multiple SchemaBook.author triples, one for each author
  /// ```
  ///
  /// Example forcing a collection to be treated as a single value:
  /// ```dart
  /// @RdfProperty(
  ///   SchemaBook.keywords,
  ///   collection: RdfCollectionType.none
  /// )
  /// final List<String> tags; // Generates a single triple with the entire list as one value
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
  /// - [iri]: Use when the property value represents an IRI reference
  /// - [localResource]: Use when the property value is a nested resource that should be a blank node
  /// - [literal]: Use when the property value needs custom literal serialization
  /// - [globalResource]: Use when the property value is a resource with its own global IRI
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
