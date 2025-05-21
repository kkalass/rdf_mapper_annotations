import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a Dart class as a local RDF resource (referred to via a blank node).
///
/// Local resources represent embedded entities that don't need globally unique
/// identifiers and whose identity depends on the context of their parent resource.
///
/// Instances of the annotated class will be mapped to blank nodes in RDF triples
/// by a corresponding mapper - either a mapper generated automatically from this
/// annotation, or a mapper that you implement manually and register with `rdf_mapper`.
///
/// When using the standard constructor (`@RdfLocalResource(classIri)`), a mapper is
/// automatically generated based on the property annotations (like `@RdfProperty`)
/// in your class and registered within initRdfMapper. This generated mapper will
/// create RDF triples with the blank node as the subject for each annotated property.
///
/// Unlike `@RdfGlobalResource`, instances with this annotation will be mapped to
/// blank nodes (anonymous resources) rather than resources with IRIs.
///
/// With custom mappers, the actual RDF triple generation depends on your mapper
/// implementation, regardless of any property annotations.
///
/// Use this for value objects or components that only make sense in the context of
/// their parent entity.
///
/// You can use this annotation in several ways, depending on your mapping needs:
/// 1. Standard: With a class IRI (`@RdfLocalResource(classIri)`) - the mapper is
///    automatically generated and registered within initRdfMapper
/// 2. Named mapper: With `@RdfLocalResource.namedMapper()` - you must implement
///    the mapper, instantiate it, and provide it to `initRdfMapper` as a named
///    parameter
/// 3. Mapper type: With `@RdfLocalResource.mapper()` - you must implement the
///    mapper, it will be instantiated and registered within initRdfMapper
///    automatically
/// 4. Mapper instance: With `@RdfLocalResource.mapperInstance()` - you must
///    implement the mapper, your instance will be registered within initRdfMapper
///    automatically
///
/// Note: Besides using this annotation at the class level, you can also use it as
/// a parameter in the `@RdfProperty` annotation with the `localResource` parameter.
/// This allows you to specify custom mappers for specific relationships, which is
/// especially useful when you need different mapping behaviors for the same type
/// depending on the context. See `RdfProperty.localResource` for more details.
///
/// Example:
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
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
class RdfLocalResource extends BaseMapping<LocalResourceMapper>
    implements RdfAnnotation {
  /// The RDF class IRI for this blank node.
  ///
  /// This defines the RDF type of the blank node using the `rdf:type` predicate.
  final IriTerm? classIri;

  /// Creates an annotation for a class to be mapped to a blank node.
  ///
  /// This standard constructor enables automatic generation of a mapper that will
  /// create RDF triples from instances of the annotated class. The generated
  /// mapper is automatically registered within initRdfMapper.
  ///
  /// [classIri] specifies the `rdf:type` for the blank node, which defines what kind
  /// of entity this is in RDF terms. It is optional, but it's highly recommended to
  /// provide a class IRI to ensure proper typing in the RDF graph.
  ///
  /// Unlike `RdfGlobalResource`, no IRI construction strategy is needed since blank
  /// nodes are anonymous resources that do not have permanent identifiers.
  ///
  /// Example:
  /// ```dart
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
  const RdfLocalResource(this.classIri) : super();

  /// Creates a reference to a named mapper that will be injected at runtime.
  ///
  /// This constructor is used when you want to provide a custom
  /// `LocalResourceMapper` implementation for this class via dependency
  /// injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will correspond to a parameter in the generated `initRdfMapper`
  /// function.
  ///
  /// Example:
  /// ```dart
  /// @RdfLocalResource.namedMapper('customChapterMapper')
  /// class Chapter {
  ///   // ...
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyChapterMapper implements LocalResourceMapper<Chapter> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final chapterMapper = MyChapterMapper();
  /// final rdfMapper = initRdfMapper({customChapterMapper: chapterMapper});
  /// ```
  const RdfLocalResource.namedMapper(String name)
      : classIri = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle mapping
  /// for this class. The type must implement `LocalResourceMapper<T>` where T
  /// is the annotated class and it must have a no-argument default constructor.
  ///
  /// Example:
  /// ```dart
  /// @RdfLocalResource.mapper(CustomChapterMapper)
  /// class Chapter {
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class CustomChapterMapper implements LocalResourceMapper<Chapter> {
  ///   // Implementation details...
  /// }
  /// ```
  const RdfLocalResource.mapper(Type mapperType)
      : classIri = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this local
  /// resource.
  ///
  /// This allows you to supply a pre-existing instance of a `LocalResourceMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const chapterMapper = CustomChapterMapper(
  ///   validation: strictValidation,
  ///   options: chapterOptions,
  /// );
  ///
  /// @RdfLocalResource.mapperInstance(chapterMapper)
  /// class Chapter {
  ///   // ...
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfLocalResource.mapperInstance(LocalResourceMapper instance)
      : classIri = null,
        super.mapperInstance(instance);
}

/// Configures mapping details for local resources (blank nodes).
///
/// This class is used specifically within the `@RdfProperty` annotation to customize
/// how objects are serialized as blank nodes in RDF, allowing property-specific
/// mapping behavior that overrides the class-level configuration.
///
/// In RDF, blank nodes represent anonymous resources that exist within the context of
/// their parent resource, rather than having globally unique identifiers. This mapping
/// is ideal for:
///
/// - Composite objects or value objects
/// - Nested structures where identity outside the parent context isn't needed
/// - Objects that semantically don't make sense as standalone entities
///
/// Example:
/// ```dart
/// @RdfProperty(
///   SchemaBook.chapter,
///   localResource: LocalResourceMapping.namedMapper('customChapterMapper')
/// )
/// final Chapter firstChapter;
/// ```
///
/// Without this override, the property would use the default mapper registered for
/// the `Chapter` class, which might be configured with `@RdfLocalResource` at the class level.
class LocalResourceMapping extends BaseMapping<LocalResourceMapper> {
  /// Creates a reference to a named mapper that will be injected at runtime.
  ///
  /// Use this constructor when you want to provide your own custom
  /// `LocalResourceMapper` implementation rather than using the automatic generator.
  /// The mapper you provide will determine how instances of the class are mapped to
  /// RDF subjects. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The `name` will correspond to a parameter in the generated `initRdfMapper` function.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource.namedMapper('customBookMapper')
  /// class Book {
  ///   // ...
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyBookMapper implements GlobalResourceMapper<Book> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final bookMapper = MyBookMapper();
  /// final rdfMapper = initRdfMapper({customBookMapper: bookMapper});
  /// ```
  const LocalResourceMapping.namedMapper(String name) : super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// Use this constructor when you want to provide your own custom mapper implementation
  /// rather than using the automatic generator. The mapper you provide will determine
  /// how instances of the class are mapped to RDF subjects.
  ///
  /// The generator will create an instance of `mapperType` to handle mapping
  /// for instances of this class. The type must implement `LocalResourceMapper<T>` where T
  /// is the annotated class and it must have a no-argument default constructor.
  ///
  /// Example:
  /// ```dart
  /// @RdfLocalResource.mapper(CustomChapterMapper)
  /// class Chapter {
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class CustomChapterMapper implements LocalResourceMapper<Chapter> {
  ///   // Implementation details...
  /// }
  /// ```
  const LocalResourceMapping.mapper(Type mapperType) : super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this local
  /// resource.
  ///
  /// This allows you to supply a pre-existing instance of a `LocalResourceMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const chapterMapper = CustomChapterMapper(
  ///   validation: strictValidation,
  ///   options: chapterOptions,
  /// );
  ///
  /// @RdfLocalResource.mapperInstance(chapterMapper)
  /// class Chapter {
  ///   // ...
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const LocalResourceMapping.mapperInstance(LocalResourceMapper instance)
      : super.mapperInstance(instance);
}
