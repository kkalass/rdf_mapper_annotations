import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';
import 'package:rdf_mapper_annotations/src/term/iri.dart';

/// Marks a Dart class as an RDF resource with a global IRI.
///
/// This annotation provides a declarative way to indicate that instances of this
/// class should be mapped to RDF subjects with specific IRIs. When using the
/// annotation, a mapper is either generated automatically based on the annotation
/// or you can implement a custom mapper manually.
///
/// Note that manually implemented and registered mappers don't require this
/// annotation at all - you can map any class to RDF by implementing the
/// appropriate mapper interface and registering an instance with the `RdfMapper` facade.
///
/// When using the standard constructor (`@RdfGlobalResource(classIri, iriStrategy)`),
/// a mapper is automatically generated based on the property annotations (like
/// `@RdfProperty`) in your class. By default, this mapper is registered within
/// `initRdfMapper` (when [registerGlobally] is true). This generated mapper will
/// create RDF triples with the instance's IRI as the subject for each annotated property.
///
/// Set [registerGlobally] to `false` if this mapper should not be registered
/// automatically. This is useful when the mapper requires constructor parameters
/// that are only available at runtime and should be provided via `@Provider`
/// annotations in the parent class.
///
/// The instance's IRI is computed using the provided iriStrategy (please refer to
/// the `@RdfIri` documentation for details on how IRIs are constructed).
///
/// With custom mappers, the actual RDF triple generation depends on your mapper
/// implementation, regardless of any property annotations.
///
/// Global resources represent entities with unique identifiers that can be referenced directly
/// by other entities in the RDF graph.
///
/// You can use this annotation in several ways, depending on your mapping needs:
/// 1. Standard: Use `@RdfGlobalResource(classIri, iriStrategy)` with an IRI template - the mapper is automatically generated and registered within initRdfMapper
/// 2. Named mapper: Use `@RdfGlobalResource.namedMapper()` - you must implement the mapper, instantiate it, and provide it to `initRdfMapper` as a named parameter
/// 3. Mapper type: Use `@RdfGlobalResource.mapper()` - you must implement the mapper, it will be instantiated and registered within initRdfMapper automatically
/// 4. Mapper instance: Use `@RdfGlobalResource.mapperInstance()` - you must implement the mapper, your instance will be registered within initRdfMapper automatically
///
/// This annotation is typically used for:
/// - Domain entities with unique identifiers
/// - Resources that need to be referenced from multiple places
/// - Top-level objects in your data model
/// - Entities that might be referenced by external systems
///
/// Note: Besides using this annotation at the class level, you can also use it as a parameter
/// in the `@RdfProperty` annotation with the `globalResource` parameter. This primarily allows you to
/// specify custom mappers for specific relationships, overriding the globally registered mapper.
/// This is especially useful when you need different mapping behaviors for the same type depending
/// on the context where it's used. See `RdfProperty.globalResource` for more details and examples.
///
/// Example with IRI template:
/// ```dart
/// // Define a book with a globally unique IRI pattern
/// @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
/// class Book {
///   @RdfIriPart('id')
///   final String id;
///
///   @RdfProperty(SchemaBook.name)
///   final String title;
///
///   @RdfProperty(SchemaBook.author)
///   final Person author;
///   // ...
/// }
/// ```
///
/// Example with custom named mapper:
/// ```dart
/// @RdfGlobalResource.namedMapper('customBookMapper')
/// class Book {
///   // ...
/// }
///
/// // In initialization code:
/// initRdfMapper({required GlobalResourceMapper<Book> customBookMapper}) { ... }
/// ```
class RdfGlobalResource extends BaseMappingAnnotation<GlobalResourceMapper>
    implements RdfAnnotation {
  /// The RDF class IRI for this resource.
  ///
  /// This defines the RDF type of the resource using the `rdf:type` predicate.
  /// It's typically an [IriTerm] from a vocabulary like `SchemaBook.classIri`.
  final IriTerm? classIri;

  /// The [IriStrategy] annotation specifying how the IRI for this resource is constructed.
  final IriStrategy? iri;

  /// Creates an annotation for a class whose instances will be mapped to RDF
  /// subjects with specific IRIs.
  ///
  /// This standard constructor creates a mapper that will
  /// create RDF triples from instances of the annotated class. The generated
  /// mapper is automatically registered within `initRdfMapper` when [registerGlobally]
  /// is `true` (the default).
  ///
  /// Set [registerGlobally] to `false` if this mapper should not be registered
  /// automatically. This is useful when:
  /// - The mapper requires constructor parameters that are only available at runtime
  /// - The mapper is only used in specific contexts via `@Provider` annotations
  /// - You want to manually manage the mapper registration
  ///
  /// [classIri] specifies the `rdf:type` for the resource, which defines what kind
  /// of entity this is in RDF terms. It is optional, but it's highly recommended to
  /// provide a class IRI to ensure proper typing in the RDF graph.
  /// [iriStrategy] defines the IRI construction strategy for instances of this class, which
  /// determines how unique identifiers are generated for each instance
  /// (typically based on annotated properties).
  /// [registerGlobally] controls whether the generated mapper should be registered globally
  /// in the `initRdfMapper` function. Set to `false` when the mapper should not be
  /// globally accessible, typically when all required context will be provided by parent
  /// objects via `@RdfProvides` annotations.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
  /// class Book {
  ///   @RdfIriPart('id')
  ///   final String id;
  ///   // ...
  /// }
  /// ```
  const RdfGlobalResource(this.classIri, IriStrategy iriStrategy,
      {super.registerGlobally = true})
      : iri = iriStrategy,
        super();

  /// Creates a reference to a named mapper for this global resource.
  ///
  /// Use this constructor when you want to provide a custom `GlobalResourceMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The `name` will correspond to a parameter in the generated `initRdfMapper` function.
  ///
  /// This approach is particularly useful for resources that require complex mapping
  /// logic or external context (like base URLs) that might vary between deployments.
  ///
  /// Note: The mapper will be registered globally in the `RdfMapper` instance.
  /// If you need non-global registration, simply do not annotate the class with `@RdfGlobalResource`.
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
  const RdfGlobalResource.namedMapper(String name)
      : iri = null,
        classIri = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// Use this constructor when you want to provide your own custom mapper implementation
  /// rather than using the automatic generator. The mapper you provide will determine
  /// how instances of the class are mapped to RDF subjects.
  ///
  /// The generator will create an instance of `mapperType` to handle mapping
  /// for instances of this class. The type must implement `GlobalResourceMapper<T>` where T
  /// is the annotated class.
  ///
  /// Note: The mapper will be registered globally in the `RdfMapper` instance.
  /// If you need non-global registration, do not annotate your class with `@RdfGlobalResource`.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource.mapper(CustomBookMapper)
  /// class Book {
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator and
  /// // it must provide a no-argument constructor:
  /// class CustomBookMapper implements GlobalResourceMapper<Book> {
  ///   // Implementation details...
  /// }
  /// ```
  const RdfGlobalResource.mapper(Type mapperType)
      : iri = null,
        classIri = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance.
  ///
  /// Use this constructor when you want to provide your own pre-configured mapper
  /// implementation rather than using the automatic generator. The mapper you provide
  /// will determine how instances of the class are mapped to RDF subjects.
  ///
  /// This allows you to supply a pre-existing instance of a `GlobalResourceMapper`
  /// for this class.
  ///
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const bookMapper = CustomBookMapper(
  ///   includeMetadata: true,
  ///   defaultLanguage: 'en',
  /// );
  ///
  /// @RdfGlobalResource.mapperInstance(bookMapper)
  /// class Book {
  ///   // ...
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfGlobalResource.mapperInstance(GlobalResourceMapper instance)
      : iri = null,
        classIri = null,
        super.mapperInstance(instance);
}

/// Configures mapping details for global resources (resources with IRIs).
///
/// This class is used specifically within the `@RdfProperty` annotation to customize
/// how objects are serialized as global resources in RDF, allowing property-specific
/// mapping behavior that can override the class-level configuration.
///
/// Use this class when you need to:
/// - Override the default mapper for a property's type
/// - Apply specialized mapping logic for a specific relationship
/// - Use a different mapping strategy for the same type in different contexts
///
/// Example:
/// ```dart
/// @RdfProperty(
///   SchemaBook.publisher,
///   globalResource: GlobalResourceMapping.namedMapper('specialPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
class GlobalResourceMapping extends BaseMapping<GlobalResourceMapper> {
  /// Creates a reference to a named mapper that will be injected at runtime.
  ///
  /// Use this constructor when you want to provide your own custom
  /// `GlobalResourceMapper` implementation rather than using the automatic generator.
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
  const GlobalResourceMapping.namedMapper(String name)
      : super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// Use this constructor when you want to provide your own custom mapper implementation
  /// rather than using the automatic generator. The mapper you provide will determine
  /// how instances of the class are mapped to RDF subjects.
  ///
  /// The generator will create an instance of `mapperType` to handle mapping
  /// for instances of this class. The type must implement `GlobalResourceMapper<T>` where T
  /// is the annotated class.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource.mapper(CustomBookMapper)
  /// class Book {
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator and
  /// // it must provide a no-argument constructor:
  /// class CustomBookMapper implements GlobalResourceMapper<Book> {
  ///   // Implementation details...
  /// }
  /// ```
  const GlobalResourceMapping.mapper(Type mapperType)
      : super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance.
  ///
  /// Use this constructor when you want to provide your own pre-configured mapper
  /// implementation rather than using the automatic generator. The mapper you provide
  /// will determine how instances of the class are mapped to RDF subjects.
  ///
  /// This allows you to supply a pre-existing instance of a `GlobalResourceMapper`
  /// for this class.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const bookMapper = CustomBookMapper(
  ///   includeMetadata: true,
  ///   defaultLanguage: 'en',
  /// );
  ///
  /// @RdfGlobalResource.mapperInstance(bookMapper)
  /// class Book {
  ///   // ...
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const GlobalResourceMapping.mapperInstance(GlobalResourceMapper instance)
      : super.mapperInstance(instance);
}
