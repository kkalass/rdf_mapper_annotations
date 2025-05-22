import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a Dart class as representing an RDF IRI term.
///
/// This annotation is used for classes that represent identifiers or references
/// that should be serialized as IRIs (Internationalized Resource Identifiers)
/// in RDF graphs:
///
/// - URIs and URLs
/// - ISBNs, DOIs, and other standardized identifiers
/// - Domain-specific identifiers with structured formats
///
/// When you annotate a class with `@RdfIri`, a mapper is created that handles
/// the conversion between your Dart class and IRI terms.
///
/// ## IRI Generation
///
/// The IRI is computed using:
///
/// 1. An optional **template pattern** with variables in curly braces, e.g., `urn:isbn:{value}`
/// 2. Properties annotated with `@RdfIriPart` that provide values for these variables
/// 3. For the simplest case without a template, the property marked with `@RdfIriPart`
///    is used directly as the complete IRI
///
/// ## Usage Options
///
/// You can define how your class is mapped in several ways:
///
/// 1. **Template-based** - `@RdfIri('prefix:{value}')`
/// 2. **Direct value** - `@RdfIri()` (uses the `@RdfIriPart` property value as-is)
/// 3. **External mappers** - `.namedMapper()`, `.mapper()`, or `.mapperInstance()`
///
/// By default, the generated mapper is registered globally in `initRdfMapper`. Set
/// [registerGlobally] to `false` if this mapper should not be registered
/// automatically. This is useful when the mapper requires constructor parameters
/// that are only available at runtime and should be provided via `@Provider`
/// annotations in the parent class.
///
/// ## Property-Level Usage
///
/// You can also apply this as part of an `@RdfProperty` annotation to override
/// IRI mapping for a specific property:
///
/// ```dart
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('https://example.org/users/{userId}')
/// )
/// final String userId;
/// ```
///
/// ## Examples
///
/// **Template-based IRI:**
/// ```dart
/// @RdfIri('urn:isbn:{value}')
/// class ISBN {
///   @RdfIriPart() // 'value' is inferred from property name
///   final String value;
///
///   ISBN(this.value);
///   // Serialized as: urn:isbn:9780261102217
/// }
/// ```
///
/// **Direct value as IRI:**
/// ```dart
/// @RdfIri()
/// class AbsoluteUri {
///   @RdfIriPart()
///   final String uri;
///
///   AbsoluteUri(this.uri);
///   // Uses the value directly as IRI: 'https://example.org/resource/123'
/// }
/// ```
class RdfIri extends BaseMappingAnnotation<IriTermMapper>
    implements RdfAnnotation {
  /// An optional template string for constructing the IRI.
  ///
  /// Template variables are enclosed in curly braces and can be of two types:
  ///
  /// 1. **Class property variables**: Correspond to properties in the class marked with `@RdfIriPart`
  ///    - Example: In `@RdfIri('urn:isbn:{value}')`, the `{value}` variable will be replaced with
  ///      the value of the property marked with `@RdfIriPart()` (or `@RdfIriPart('value')`)
  ///    - When multiple properties use `@RdfIriPart.position()`, the generator creates a record-based
  ///      mapper to handle complex multi-part IRIs
  ///
  /// 2. **Context variables**: Variables like `{baseUri}` or `{storageRoot}` that are provided
  ///    through one of two methods:
  ///    - Via global provider functions in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`).
  ///      The generator will automatically add a required parameter to `initRdfMapper`.
  ///    - Via other properties in the same class annotated with `@RdfProvides('baseUri')`.
  ///      This is preferred for context variables that are already available in the class.
  ///
  /// If no template is provided (`template == null`), the property marked with `@RdfIriPart`
  /// will be used as the complete IRI value.
  final String? template;

  /// Creates an annotation for a class to be mapped to an IRI term.
  ///
  /// This standard constructor creates a mapper that automatically handles the
  /// conversion between your class and an IRI term. By default, this mapper is
  /// registered within `initRdfMapper` when [registerGlobally] is `true`.
  ///
  /// The mapper uses:
  ///
  /// - An optional [template] with placeholders like `{propertyName}` that will be
  ///   replaced with values from properties marked with `@RdfIriPart`
  /// - If no template is provided, the property marked with `@RdfIriPart` will be
  ///   used directly as the complete IRI
  ///
  /// Examples:
  /// ```dart
  /// // With template
  /// @RdfIri('urn:isbn:{value}')
  /// class ISBN {
  ///   @RdfIriPart()
  ///   final String value;
  ///   // ...
  /// }
  ///
  /// // Without template (direct value)
  /// @RdfIri()
  /// class Uri {
  ///   @RdfIriPart()
  ///   final String value;
  ///   // ...
  /// }
  /// ```
  ///
  /// The [registerGlobally] parameter determines whether the generated mapper is
  /// registered globally in `initRdfMapper`. If set to `false`, the mapper will
  /// not be registered automatically and must be provided via `@Provider`
  /// annotations in the parent class.
  const RdfIri([this.template, bool registerGlobally = true])
      : super(registerGlobally: registerGlobally);

  /// Creates a reference to a named mapper for this IRI term.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will be used as a parameter name in the generated `initRdfMapper` function.
  ///
  /// This approach is particularly useful for IRIs that require complex logic or
  /// external context (like base URLs) that might vary between deployments.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.namedMapper('userReferenceMapper')
  /// class UserReference {
  ///   final String username;
  ///   UserReference(this.username);
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyUserReferenceMapper implements IriTermMapper<UserReference> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final userRefMapper = MyUserReferenceMapper();
  /// initRdfMapper({
  ///   required IriTermMapper<UserReference> userReferenceMapper: userRefMapper
  /// }) { ... }
  /// ```
  const RdfIri.namedMapper(String name)
      : template = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper`.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.mapper(StandardIsbnMapper)
  /// class ISBN {
  ///   final String value;
  ///   ISBN(this.value);
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class StandardIsbnMapper implements IriTermMapper<ISBN> {
  ///   @override
  ///   IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
  ///     return IriTerm('urn:isbn:${isbn.value}');
  ///   }
  ///
  ///   @override
  ///   ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final iri = term.iri;
  ///     if (!iri.startsWith('urn:isbn:')) {
  ///       throw ArgumentError('Invalid ISBN IRI: $iri');
  ///     }
  ///     return ISBN(iri.substring(9));
  ///   }
  /// }
  /// ```
  const RdfIri.mapper(Type mapperType)
      : template = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// to handle mapping for this class without dependency injection.
  ///
  /// This approach is ideal when your mapper requires configuration that must be
  /// provided at initialization time, such as base URLs or formatting parameters.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const catalogMapper = ProductCatalogMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// @RdfIri.mapperInstance(catalogMapper)
  /// class ProductReference {
  ///   final String sku;
  ///   ProductReference(this.sku);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfIri.mapperInstance(IriTermMapper instance)
      : template = null,
        super.mapperInstance(instance);
}

/// Configures mapping details for IRI terms in RDF.
///
/// This class is used within the `@RdfProperty` annotation to customize how objects
/// are serialized as IRI terms in RDF, allowing property-specific mapping behavior
/// that overrides the class-level configuration defined with `@RdfIri`.
///
/// IRI mapping is typically used for:
///
/// - Properties representing identifiers that need custom formatting as IRIs
/// - References to other resources with specific IRI patterns
/// - Properties that must be serialized as IRIs rather than literals
/// - Customizing resource references for specific relationship contexts
///
/// Example:
/// ```dart
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('https://example.org/users/{userId}')
/// )
/// final String userId;
/// ```
class IriMapping extends BaseMapping<IriTermMapper> {
  /// An optional template string for constructing the IRI.
  ///
  /// Template variables are enclosed in curly braces and can be of two types:
  ///
  /// 1. **Property variables**: Correspond to values from the property this mapping is applied to
  ///    - Example: In `IriMapping('urn:isbn:{userId}')`, the `{userId}` variable will be replaced with
  ///      the value of the property it's applied to
  ///    - The actual property name is used as the placeholder, creating a clear connection between
  ///      the template and the property
  ///    - The property itself doesn't need additional `@RdfIriPart` annotations
  ///
  /// 2. **Context variables**: Variables like `{baseUri}` or `{storageRoot}` that are provided
  ///    through one of two methods:
  ///    - Via global provider functions in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`).
  ///      The generator will automatically add a required parameter to `initRdfMapper`.
  ///    - Via other properties in the same class annotated with `@RdfProvides('baseUri')`.
  ///      This is preferred for context variables that are already available in the class.
  ///    - Example: `IriMapping('{baseUri}/users/{userId}')`
  ///
  /// If no template is provided (`template == null`), the property value will be used directly
  /// as the complete IRI, which is useful for properties that already contain fully qualified URIs.
  final String? template;

  /// Creates an IRI mapping template for property-specific IRI generation.
  ///
  /// Use this constructor to customize how a specific property should be
  /// transformed into an IRI term in the RDF graph.
  ///
  /// The [template] defines the pattern for constructing IRIs from the property value:
  /// - With a template: `IriMapping('http://example.org/users/{value}')`
  /// - Without a template: `IriMapping()` - uses the property value directly as the IRI
  ///
  /// This is particularly useful when the property contains identifier information
  /// that needs to be formatted in a specific way to create valid IRIs.
  ///
  /// Example:
  /// ```dart
  /// @RdfProperty(
  ///   Dcterms.source,
  ///   iri: IriMapping('urn:isbn:{isbn}')
  /// )
  /// final String isbn; // Will be mapped to an IRI like "urn:isbn:9780123456789"
  /// ```
  const IriMapping([this.template]) : super();

  /// Creates a reference to a named mapper for this IRI term.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will be used as a parameter name in the generated `initRdfMapper` function.
  ///
  /// This approach is particularly useful for IRIs that require complex logic or
  /// external context (like base URLs) that might vary between deployments.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.namedMapper('userReferenceMapper')
  /// class UserReference {
  ///   final String username;
  ///   UserReference(this.username);
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyUserReferenceMapper implements IriTermMapper<UserReference> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final userRefMapper = MyUserReferenceMapper();
  /// initRdfMapper({
  ///   required IriTermMapper<UserReference> userReferenceMapper: userRefMapper
  /// }) { ... }
  /// ```
  const IriMapping.namedMapper(String name)
      : template = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper`.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.mapper(StandardIsbnMapper)
  /// class ISBN {
  ///   final String value;
  ///   ISBN(this.value);
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class StandardIsbnMapper implements IriTermMapper<ISBN> {
  ///   @override
  ///   IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
  ///     return IriTerm('urn:isbn:${isbn.value}');
  ///   }
  ///
  ///   @override
  ///   ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final iri = term.iri;
  ///     if (!iri.startsWith('urn:isbn:')) {
  ///       throw ArgumentError('Invalid ISBN IRI: $iri');
  ///     }
  ///     return ISBN(iri.substring(9));
  ///   }
  /// }
  /// ```
  const IriMapping.mapper(Type mapperType)
      : template = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// to handle mapping for this class without dependency injection.
  ///
  /// This approach is ideal when your mapper requires configuration that must be
  /// provided at initialization time, such as base URLs or formatting parameters.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const catalogMapper = ProductCatalogMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// @RdfIri.mapperInstance(catalogMapper)
  /// class ProductReference {
  ///   final String sku;
  ///   ProductReference(this.sku);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const IriMapping.mapperInstance(IriTermMapper instance)
      : template = null,
        super.mapperInstance(instance);
}

/// Defines the strategy for generating IRIs for RDF resources.
///
/// This class is a key component of the `@RdfGlobalResource` annotation that specifies
/// how to construct unique IRIs for instances of annotated classes. It provides a
/// template-based mechanism that combines static text with dynamic values from object properties.
///
/// The IRI template supports two types of variables:
///
/// 1. **Property-based variables** - Values from object properties marked with `@RdfIriPart`:
///    ```dart
///    @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/books/{isbn}'))
///    class Book {
///      @RdfIriPart('isbn')  // Maps to {isbn} in the template
///      final String isbn;
///      // ...
///    }
///    ```
///
/// 2. **Context variables** - Values provided through one of two methods:
///    ```dart
///    @RdfGlobalResource(
///      SchemaBook.classIri,
///      IriStrategy('{baseUrl}/books/{id}')  // {baseUrl} is a context variable
///    )
///    class Book {
///      @RdfIriPart('id')
///      final String id;
///
///      // Option 1: Provide the context variable within the class
///      @RdfProvides('baseUrl')
///      final String apiUrl = 'https://myapp.example.org';
///      // ...
///    }
///
///    // Option 2: Via initialization code:
///    final rdfMapper = initRdfMapper(
///      baseUrlProvider: () => 'https://myapp.example.org'  // Provides value for {baseUrl}
///    );
///    ```
///
/// You can combine both types of variables in a single template to create flexible,
/// context-aware IRI patterns for your resources. Unlike the `RdfIri` annotation which is used
/// for classes that represent IRI terms themselves, `IriStrategy` is used within `RdfGlobalResource`
/// to define how instance IRIs are constructed from their properties.
class IriStrategy extends BaseMapping<IriTermMapper> {
  /// An optional template string for constructing the IRI.
  ///
  /// Template variables are enclosed in curly braces and can be of two types:
  ///
  /// 1. **Class property variables**: Correspond to properties in the class marked with `@RdfIriPart`
  ///    - Example: In `IriStrategy('urn:isbn:{isbn}')`, the `{isbn}` variable will be replaced with
  ///      the value of the property marked with `@RdfIriPart('isbn')`
  ///    - You can use multiple properties to create complex IRIs like `{baseUrl}/users/{userId}/profiles/{profileId}`
  ///
  /// 2. **Context variables**: Variables like `{baseUrl}` or `{storageRoot}` that can be provided
  ///    through one of two methods:
  ///    - Via global provider functions in `initRdfMapper` (e.g., `baseUrlProvider: () => 'https://example.com'`).
  ///      The generator will automatically add a required parameter to `initRdfMapper`.
  ///    - Via properties in the same class annotated with `@RdfProvides('baseUrl')`, which is
  ///      preferred for context variables already available in the class.
  ///
  /// If no template is provided (`template == null`), the property marked with `@RdfIriPart`
  /// will be used as the complete IRI value.
  final String? template;

  /// Creates an annotation for a class to be mapped to an IRI term.
  ///
  /// An optional [template] can be provided to define how the IRI is constructed.
  /// If no template is provided, the property value marked with `@RdfIriPart`
  /// will be used directly as the complete IRI. When using this standard constructor,
  /// the mapper is automatically generated and registered within initRdfMapper.
  const IriStrategy([this.template]) : super();

  /// Creates a reference to a named mapper for this IRI term.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will be used as a parameter name in the generated `initRdfMapper` function.
  ///
  /// This approach is particularly useful for IRIs that require complex logic or
  /// external context (like base URLs) that might vary between deployments.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.namedMapper('userReferenceMapper')
  /// class UserReference {
  ///   final String username;
  ///   UserReference(this.username);
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyUserReferenceMapper implements IriTermMapper<UserReference> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final userRefMapper = MyUserReferenceMapper();
  /// initRdfMapper({
  ///   required IriTermMapper<UserReference> userReferenceMapper: userRefMapper
  /// }) { ... }
  /// ```
  const IriStrategy.namedMapper(String name)
      : template = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper`.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.mapper(StandardIsbnMapper)
  /// class ISBN {
  ///   final String value;
  ///   ISBN(this.value);
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class StandardIsbnMapper implements IriTermMapper<ISBN> {
  ///   @override
  ///   IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
  ///     return IriTerm('urn:isbn:${isbn.value}');
  ///   }
  ///
  ///   @override
  ///   ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final iri = term.iri;
  ///     if (!iri.startsWith('urn:isbn:')) {
  ///       throw ArgumentError('Invalid ISBN IRI: $iri');
  ///     }
  ///     return ISBN(iri.substring(9));
  ///   }
  /// }
  /// ```
  const IriStrategy.mapper(Type mapperType)
      : template = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// to handle mapping for this class without dependency injection.
  ///
  /// This approach is ideal when your mapper requires configuration that must be
  /// provided at initialization time, such as base URLs or formatting parameters.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const catalogMapper = ProductCatalogMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// @RdfIri.mapperInstance(catalogMapper)
  /// class ProductReference {
  ///   final String sku;
  ///   ProductReference(this.sku);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const IriStrategy.mapperInstance(IriTermMapper instance)
      : template = null,
        super.mapperInstance(instance);
}

/// Marks a property as a part of the IRI for the enclosing class.
///
/// Used in classes annotated with `@RdfIri` or `@RdfGlobalResource` to designate
/// properties that contribute to IRI construction. This annotation creates a binding
/// between template variables and property values.
///
/// Example with named template variable:
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
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
  const RdfIriPart.position(int position, [this.name]) : pos = position;
}
