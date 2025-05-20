/// Annotation library for mapping Dart classes to RDF graphs.
///
/// This library provides a set of annotations that can be applied to Dart classes and
/// properties to declare how they should be mapped to and from RDF graphs. Used in
/// conjunction with the `rdf_mapper_generator` package, these annotations enable
/// automatic generation of mapper implementations.
///
/// The primary annotations are organized into two categories:
///
/// **Class-level annotations** define how a class is mapped to RDF nodes:
/// - [RdfGlobalResource]: For entities with unique IRIs (subjects)
/// - [RdfLocalResource]: For nested entities as blank nodes
/// - [RdfIri]: For classes representing IRIs
/// - [RdfLiteral]: For classes representing literal values
///
/// **Property-level annotations** define how properties are mapped:
/// - [RdfProperty]: Main property annotation, links to an RDF predicate
/// - [RdfIriPart]: Marks properties that contribute to IRI construction
/// - [RdfValue]: Identifies the value source for literal serialization
/// - [RdfCollectionOf]: Specifies item type for collections
///
/// For usage examples, see the [example](https://github.com/kkalass/rdf_mapper_annotations/tree/main/example) directory.
library;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Base annotation interface for RDF mapper generation.
///
/// This is a marker interface for all RDF mapping annotations used by the
/// `rdf_mapper_generator` package to automatically generate implementations
/// of the `rdf_mapper` interfaces. These annotations enable a declarative
/// approach to mapping between Dart objects and RDF graphs.
abstract class RdfAnnotation {
  const RdfAnnotation();
}

// --- Type-safe mapper references ---

/// Base class for type-safe mapper references.
///
/// Used internally by annotations like [RdfGlobalResource], [RdfLocalResource],
/// [RdfIri], and [RdfLiteral] to specify how custom mappers should be provided
/// to the generated code. This class enables flexible dependency injection and
/// customization options.
class MapperRef<M> {
  /// The name to use for the mapper parameter in the generated `initRdfMapper`
  /// method. Enables dependency injection of specific mapper instances.
  final String? name;

  /// The [Type] of the mapper to instantiate. The generator will create an
  /// instance of this type at runtime.
  final Type? type;

  /// A direct mapper instance to be used. Allows for pre-configured
  /// mapper instances with specific behaviors.
  final M? instance;

  /// Creates a mapper reference with optional injection configuration.
  const MapperRef({this.name, this.type, this.instance});
}

// --- Class-level annotations ---

/// Marks a Dart class as an RDF global resource, meaning it will be mapped
/// to an RDF IRI node (a subject in RDF triples).
///
/// Global resources have unique identifiers (IRIs) and can be referenced from
/// other resources. Use this annotation for primary entities in your data model
/// that need stable, globally unique identifiers.
///
/// The generator creates a `GlobalResourceMapper` for each annotated class.
///
/// Example with IRI template:
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, RdfIri('http://example.org/book/{id}'))
/// class Book {
///   @RdfIriPart('id')
///   final String id;
///
///   @RdfProperty(SchemaBook.name)
///   final String title;
///   // ...
/// }
/// ```
///
/// Example with custom named mapper:
/// ```dart
/// @RdfGlobalResource.namedMapper('bookMapper')
/// class Book {
///   // ...
/// }
///
/// // In initialization code:
/// initRdfMapper({required GlobalResourceMapper<Book> bookMapper}) { ... }
/// ```
class RdfGlobalResource implements RdfAnnotation {
  /// The RDF class IRI for this resource.
  ///
  /// This defines the RDF type of the resource using the `rdf:type` predicate.
  /// It's typically an [IriTerm] from a vocabulary like `SchemaBook.classIri`.
  final IriTerm? classIri;

  /// The [RdfIri] annotation specifying how the IRI for this resource is constructed.
  final RdfIri? iri;

  final String? _mapperName;
  final Type? _mapperType;
  final GlobalResourceMapper? _mapperInstance;

  /// Provides a [MapperRef] if a custom mapper is specified.
  MapperRef<GlobalResourceMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
              name: _mapperName,
              instance: _mapperInstance,
              type: _mapperType,
            )
          : null;

  /// Creates a reference to a class that will be mapped to an RDF IRI node.
  ///
  /// [classIri] specifies the `rdf:type` for the resource.
  /// [iri] defines the IRI construction strategy for instances of this class.
  const RdfGlobalResource(this.classIri, RdfIri iri)
      : iri = iri,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a named mapper that will be injected at runtime.
  ///
  /// This constructor is used when you want to provide a custom
  /// `GlobalResourceMapper` implementation for this class via dependency
  /// injection. The `name` will correspond to a parameter in the generated
  /// `initRdfMapper` function.
  const RdfGlobalResource.namedMapper(String name)
      : iri = null,
        classIri = null,
        _mapperName = name,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of `mapperType` to handle mapping
  /// for this class.
  const RdfGlobalResource.mapper(Type mapperType)
      : iri = null,
        classIri = null,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = mapperType;

  /// Creates a reference to a directly provided mapper instance.
  ///
  /// This allows you to supply a pre-existing instance of a `GlobalResourceMapper`
  /// for this class.
  const RdfGlobalResource.mapperInstance(GlobalResourceMapper instance)
      : iri = null,
        classIri = null,
        _mapperName = null,
        _mapperInstance = instance,
        _mapperType = null;
}

/// Marks a Dart class as an RDF local resource (a blank node).
///
/// Local resources represent nested entities without globally unique identifiers.
/// Use this for value objects or components that only make sense in the context
/// of their parent entity.
///
/// The generator creates a `LocalResourceMapper` for each annotated class.
///
/// Example:
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, RdfIri('http://example.org/book/{id}'))
/// class Book {
///   // ...
///   @RdfProperty(SchemaBook.hasPart)
///   final Iterable<Chapter> chapters;
/// }
///
/// @RdfLocalResource(SchemaChapter.classIri)
/// class Chapter {
///   @RdfProperty(SchemaChapter.name)
///   final String title;
///
///   @RdfProperty(SchemaChapter.position)
///   final int number;
///   // ...
/// }
/// ```
class RdfLocalResource implements RdfAnnotation {
  /// The RDF class IRI for this blank node.
  ///
  /// This defines the RDF type of the blank node using the `rdf:type` predicate.
  final IriTerm? classIri;

  final String? _mapperName;
  final Type? _mapperType;
  final LocalResourceMapper? _mapperInstance;

  /// Optional specification for a custom mapper.
  ///
  /// When provided, the generator will use this mapper instead of generating one.
  MapperRef<LocalResourceMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
              name: _mapperName,
              instance: _mapperInstance,
              type: _mapperType,
            )
          : null;

  /// Creates an annotation for a class to be mapped to a blank node.
  ///
  /// [classIri] specifies the `rdf:type` for the blank node.
  const RdfLocalResource(this.classIri)
      : _mapperName = null,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a named mapper for this local resource.
  const RdfLocalResource.namedMapper(String name)
      : classIri = null,
        _mapperName = name,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a mapper that will be instantiated from the given type.
  const RdfLocalResource.mapper(Type mapperType)
      : classIri = null,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = mapperType;

  /// Creates a reference to a directly provided mapper instance for this local resource.
  const RdfLocalResource.mapperInstance(LocalResourceMapper instance)
      : classIri = null,
        _mapperName = null,
        _mapperInstance = instance,
        _mapperType = null;
}

/// Marks a Dart class as representing an RDF IRI term.
///
/// Use this annotation for classes that represent identifiers or references,
/// which should be serialized as IRIs in RDF. Common examples include URIs,
/// ISBNs, or domain-specific identifiers.
///
/// The generator creates an `IriTermMapper` for each annotated class.
///
/// Example with template:
/// ```dart
/// @RdfIri('urn:isbn:{value}')
/// class ISBN {
///   @RdfIriPart() // 'value' is inferred from parameter name
///   final String value;
///
///   ISBN(this.value);
/// }
/// ```
///
/// Example with named mapper:
/// ```dart
/// @RdfIri.namedMapper('uriMapper')
/// class ResourceUri {
///   final String uri;
///
///   ResourceUri(this.uri);
/// }
/// ```
class RdfIri implements RdfAnnotation {
  /// An optional template string for constructing the IRI.
  ///
  /// Template variables are enclosed in curly braces (e.g., `{value}`, `{id}`).
  /// - `{value}`: If a property within the annotated class is marked with
  ///   `@RdfIriPart()` (without a name), its property name will be used. So this
  ///    means that the value property was annotated with `@RdfIriPart()` here.
  ///   If the annotation is used in the [RdfGlobalResource] annotation and  there are multiple `@RdfIriPart.position()` annotations, the generator will
  ///   expect a record type for the `IriTermMapper` and use positional substitution. But
  ///   if the annotation is used in the [RdfIri] annotation, the generator will
  ///   use all annotated fields to construct the instance and pass in the instance for serialization.
  /// - `{namedPart}`: Named template variables (e.g., `{storageRoot}`) must be
  ///   provided by a function during the `initRdfMapper` initialization.
  ///   For example, if the template is `{baseUri}/foo/{value}.ttl`,
  ///   then the generated `initRdfMapper` method might require a named parameter
  ///   `String Function() baseUriProvider`.
  final String? template;

  /// Optional specification for a custom mapper.
  ///
  /// When provided, the generator will use this mapper instead of generating
  /// IRI construction logic from the `template` or `@RdfIriPart` annotations.
  /// This takes precedence over `template`.
  MapperRef<IriTermMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
              name: _mapperName,
              instance: _mapperInstance,
              type: _mapperType,
            )
          : null;

  final String? _mapperName;
  final Type? _mapperType;
  final IriTermMapper? _mapperInstance;

  /// Creates an annotation for a class to be mapped to an IRI term.
  ///
  /// An optional [template] can be provided to define how the IRI is constructed.
  const RdfIri([this.template])
      : _mapperName = null,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a named mapper for this IRI term.
  const RdfIri.namedMapper(String name)
      : template = null,
        _mapperName = name,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a mapper that will be instantiated from the given type.
  const RdfIri.mapper(Type mapperType)
      : template = null,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = mapperType;

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  const RdfIri.mapperInstance(IriTermMapper instance)
      : template = null,
        _mapperName = null,
        _mapperInstance = instance,
        _mapperType = null;
}

/// Marks a Dart class as representing an RDF literal term.
///
/// Use this for value types with custom serialization needs beyond simple Dart
/// primitives. Examples include formatted values, constrained types, or objects
/// with specific rendering requirements.
///
/// The generator creates a `LiteralTermMapper` for each annotated class.
///
/// Example with automatic value delegation:
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // The 'stars' property value will be used as the literal value
///   final int stars;
///
///   Rating(this.stars) {
///     if (stars < 0 || stars > 5) {
///       throw ArgumentError('Rating must be between 0 and 5 stars');
///     }
///   }
/// }
/// ```
///
/// Example with custom conversion methods:
/// ```dart
/// @RdfLiteral.custom(
///   toLiteralTermMethod: 'toRdf',
///   fromLiteralTermMethod: 'fromRdf',
/// )
/// class Temperature {
///   final double celsius;
///
///   Temperature(this.celsius);
///
///   LiteralTerm toRdf() => LiteralTerm('$celsius°C');
///
///   static Temperature fromRdf(LiteralTerm term) =>
///     Temperature(double.parse(term.value.replaceAll('°C', '')));
/// }
/// ```
class RdfLiteral implements RdfAnnotation {
  /// Optional method name to use for converting the object to a [LiteralTerm].
  ///
  /// This method must be an instance method on the annotated class that
  /// returns a [LiteralTerm]. If not specified, the generator will look for
  /// a property marked with `@RdfValue` and use its value for conversion.
  final String? toLiteralTermMethod;

  /// Optional static method name to use for converting a [LiteralTerm] back to
  /// the object type.
  ///
  /// This method must be a static method on the annotated class that accepts
  /// a [LiteralTerm] and returns an instance of the annotated class. If not
  /// specified, the generator will look for a property marked with `@RdfValue`
  /// and attempt to deserialize the literal value into that property's type
  /// and pass it to the class's constructor.
  final String? fromLiteralTermMethod;

  /// Optional specification for a custom mapper.
  ///
  /// When provided, the generator will use this mapper instead of using the
  /// `toLiteralTermMethod` or `fromLiteralTermMethod`. This takes precedence
  /// over custom methods.
  MapperRef<LiteralTermMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
              name: _mapperName,
              instance: _mapperInstance,
              type: _mapperType,
            )
          : null;

  final String? _mapperName;
  final Type? _mapperType;
  final LiteralTermMapper? _mapperInstance;

  /// Creates an annotation for a class to be mapped to a literal term.
  ///
  /// By default, the generator will look for a property marked with `@RdfValue`
  /// to determine the literal's value and datatype.
  const RdfLiteral()
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates an annotation for a class using custom methods for literal conversion.
  ///
  /// [toLiteralTermMethod] specifies the instance method for serialization.
  /// [fromLiteralTermMethod] specifies the static method for deserialization.
  const RdfLiteral.custom({
    required String toLiteralTermMethod,
    required String fromLiteralTermMethod,
  })  : toLiteralTermMethod = toLiteralTermMethod,
        fromLiteralTermMethod = fromLiteralTermMethod,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a named mapper for this literal term.
  const RdfLiteral.namedMapper(String name)
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        _mapperName = name,
        _mapperInstance = null,
        _mapperType = null;

  /// Creates a reference to a mapper that will be instantiated from the given type.
  const RdfLiteral.mapper(Type mapperType)
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        _mapperName = null,
        _mapperInstance = null,
        _mapperType = mapperType;

  /// Creates a reference to a directly provided mapper instance for this literal term.
  const RdfLiteral.mapperInstance(LiteralTermMapper instance)
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        _mapperName = null,
        _mapperInstance = instance,
        _mapperType = null;
}

// --- Property-level annotations ---

/// Marks a property to be mapped to/from an RDF predicate.
///
/// This is the core annotation for class properties, defining how they
/// are serialized to RDF and deserialized back to Dart objects.
///
/// **Important:** Only specify one of `iri`, `localResource`, `literal`, or
/// `globalResource` for a property, as they define mutually exclusive
/// mapping strategies.
///
/// Example for simple literal properties:
/// ```dart
/// @RdfProperty(SchemaBook.name)
/// final String title;
///
/// @RdfProperty(SchemaBook.author, required: false)
/// String? author;
/// ```
///
/// Example for a property that maps to an IRI:
/// ```dart
/// @RdfProperty(
///   Dcterms.creator,
///   iri: RdfIri('{storageRoot}/profile/{userId}.ttl')
/// )
/// late String userId;
/// ```
///
/// Example with a nested resource using custom mapper:
/// ```dart
/// @RdfProperty(
///   SchemaBook.publisher,
///   localResource: RdfLocalResource.namedMapper('publisherMapper')
/// )
/// late Publisher publisher;
/// ```
///
/// Example with a collection:
/// ```dart
/// @RdfProperty(SchemaBook.hasPart)
/// @RdfCollectionOf(Chapter) // Specifies the type of items
/// final List<Chapter> chapters;
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
  final RdfIri? iri;

  /// Optional specification for treating the property's value as a blank node.
  ///
  /// Use this when the property's value is a nested resource that should not
  /// have its own global IRI.
  final RdfLocalResource? localResource;

  /// Optional specification for treating the property's value as a literal with
  /// special handling (e.g., custom serialization/deserialization methods,
  /// language tags).
  final RdfLiteral? literal;

  /// Optional specification for treating the property's value as an RDF global resource.
  ///
  /// Use this when the property's value is a nested resource that has its own
  /// globally unique IRI.
  final RdfGlobalResource? globalResource;

  /// Optional specification for collection handling.
  ///
  /// This hint helps the generator understand how to serialize and deserialize
  /// collections (e.g., `List`, `Set`, `Map`).
  final RdfCollectionType collection;

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

/// The type of collection to use for RDF property serialization.
enum RdfCollectionType {
  /// Automatically determine collection type from property type.
  ///
  /// This default option analyzes the property type:
  /// - For `List` or `Set` types, treats as a collection of values
  /// - For other types, treats as a single value
  auto,

  /// Not a collection - treat as a single value even if the Dart type is a collection.
  ///
  /// Use this to override automatic collection detection when you want a collection
  /// property to be treated as a single value.
  none,
}

/// Marks a property as a part of the IRI for the enclosing class.
///
/// Used in classes annotated with `@RdfIri` or `@RdfGlobalResource` to designate
/// properties that contribute to IRI construction. This annotation creates a binding
/// between template variables and property values.
///
/// Example with named template variable:
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, RdfIri('http://example.org/book/{id}'))
/// class Book {
///   @RdfIriPart('id') // Property value replaces {id} in the template
///   final String id;
///   // ...
/// }
/// ```
///
/// Example with unnamed (default) template variable:
/// ```dart
/// @RdfIri('urn:isbn:{value}')
/// class ISBN {
///   @RdfIriPart() // Property name 'value' is used as the variable name
///   final String value;
///   // ...
/// }
/// ```
///
/// Example with positional parts for complex cases:
/// ```dart
/// @RdfIri.namedMapper('chapterIdMapper')
/// class Chapter {
///   @RdfIriPart.position(1) // First position in the generated record type
///   final String bookId;
///
///   @RdfIriPart.position(2) // Second position in the generated record type
///   final int chapterNumber;
///   // ...
/// }
/// ```
class RdfIriPart implements RdfAnnotation {
  /// The name of the IRI part. This corresponds to a named template variable
  /// in the `RdfIri` template (e.g., `id` for `{id}`).
  final String? name;

  /// The positional index of the IRI part, used when the IRI is constructed
  /// from multiple unnamed parts, typically for record types in custom mappers.
  final int? pos;

  /// Creates an IRI part annotation with a given [name].
  const RdfIriPart([this.name]) : pos = null;

  /// Creates an IRI part annotation with a given [position].
  const RdfIriPart.position(int position)
      : pos = position,
        name = null;
}

/// Marks a property within a class as the primary value source for RDF literal conversion.
///
/// This annotation is used within classes annotated with `@RdfLiteral`
/// to designate which property provides the value for RDF literal serialization.
/// The generator automatically detects the appropriate datatype from the property's type.
///
/// Example:
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // The int value becomes the literal value
///   final int stars;
///
///   final String description; // Not included in the RDF serialization
///
///   Rating(this.stars, this.description) {
///     if (stars < 0 || stars > 5) {
///       throw ArgumentError('Rating must be between 0 and 5 stars');
///     }
///   }
/// }
/// ```
class RdfValue implements RdfAnnotation {
  /// Marks a property as the value source for RDF serialization.
  ///
  /// The generator will delegate the conversion of this property's value
  /// to the standard serializer/deserializer registered for its datatype.
  const RdfValue();
}

/// Marks a property as providing the language tag for RDF literals.
///
/// Used within `@RdfLiteral` annotated classes to specify a property that
/// provides the language tag for language-tagged string literals (e.g., "Hello"@en).
/// Only one property per class should be annotated with `@RdfLanguageTag`,
/// and it must be of type `String`.
///
/// Example:
/// ```dart
/// @RdfLiteral()
/// class LocalizedText {
///   @RdfValue()
///   final String text;
///
///   @RdfLanguageTag()
///   final String language; // e.g., 'en', 'de', 'fr'
///
///   LocalizedText(this.text, this.language);
///
///   // When serialized to RDF, this becomes a literal like: "text"@language
/// }
/// ```
class RdfLanguageTag implements RdfAnnotation {
  const RdfLanguageTag();
}

/// Marks a property that serves as the key in a mapped `Map<K,V>` collection.
///
/// Used with `@RdfCollectionOf` when mapping to a Dart `Map`. Within the item class
/// specified by `RdfCollectionOf`, the property marked with `@RdfCollectionKey`
/// becomes the key in the resulting Map.
///
/// Example:
/// ```dart
/// @RdfProperty(VocabTerm.vectorClock)
/// @RdfCollectionOf(VectorClockEntry) // Item class with key and value annotations
/// late Map<String, int> vectorClock;
///
/// // The item class that defines the structure of map entries:
/// @RdfLocalResource(VectorClockEntryClass.classIri)
/// class VectorClockEntry {
///   @RdfProperty(VectorClockEntry.clientId)
///   @RdfCollectionKey() // This property becomes the map key
///   final String clientId;
///
///   @RdfProperty(VectorClockEntry.clockValue)
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
/// For a complete example, see the documentation for `RdfCollectionKey`.
class RdfCollectionValue extends RdfAnnotation {
  const RdfCollectionValue();
}

/// Specifies the Dart [Type] of the items within a collection property.
///
/// This annotation is required on collection properties (`List`, `Set`, `Map`)
/// to tell the generator what class represents each item in the collection.
/// Without this annotation, the generator cannot determine the item type from
/// generic type parameters due to Dart's type erasure at runtime.
///
/// Examples:
/// ```dart
/// // For a List or Set:
/// @RdfProperty(SchemaBook.hasPart)
/// @RdfCollectionOf(Chapter) // Each item is a Chapter object
/// final List<Chapter> chapters;
///
/// // For a Map:
/// @RdfProperty(TaskVocab.vectorClock)
/// @RdfCollectionOf(VectorClockEntry) // Each entry is a VectorClockEntry
/// final Map<String, int> vectorClock; // Keys and values extracted from VectorClockEntry
/// ```
class RdfCollectionOf extends RdfAnnotation {
  /// The Dart [Type] of the class representing each item in the collection.
  final Type itemClass;
  const RdfCollectionOf(this.itemClass);
}

/// Marks a property as providing a named value that can be referenced in
/// IRI templates throughout the data model.
///
/// This annotation creates a shared variable that can be used in IRI templates
/// of related resources. This is particularly useful for maintaining referential
/// integrity between related entities without duplicating logic.
///
/// Example:
/// ```dart
/// @RdfGlobalResource(
///   TaskVocab.Task.classIri,
///   RdfIri('{storageRoot}/tasks/{id}.ttl'),
/// )
/// class Task {
///   @RdfIriPart('id')
///   @RdfProvides("taskId") // Makes 'id' available as '{taskId}' in other templates
///   final String id;
///
///   @RdfProperty(TaskVocab.Task.comments)
///   @RdfCollectionOf(Comment)
///   final List<Comment> comments;
///   // ...
/// }
///
/// @RdfGlobalResource(
///   TaskVocab.Comment.classIri,
///   RdfIri('{storageRoot}/tasks/{taskId}/comments/{commentId}.ttl'),
/// )
/// class Comment {
///   @RdfIriPart('commentId')
///   final String commentId;
///   // The {taskId} in the IRI comes from the Task.id via @RdfProvides
///   // ...
/// }
/// ```
class RdfProvides extends RdfAnnotation {
  /// The name by which this provided value can be referenced in IRI templates.
  final String? name;
  const RdfProvides(this.name);
}
