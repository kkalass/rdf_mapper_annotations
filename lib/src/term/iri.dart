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
/// ## Property Requirements
///
/// For classes with `@RdfIri` using the default constructor:
/// - All properties used for serialization/deserialization **must** be annotated with `@RdfIriPart`
/// - Any property without `@RdfIriPart` will be ignored during mapping
/// - The class must be fully serializable/deserializable using only the `@RdfIriPart` properties
/// - Derived or computed properties (not needed for serialization) don't need annotations
///
/// **Important:** When using external mappers (via `.namedMapper()`, `.mapper()`, or `.mapperInstance()`),
/// the `@RdfIriPart` annotations are ignored. In this case, your custom mapper implementation is fully
/// responsible for the serialization/deserialization logic.
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
/// that are only available at runtime and should be provided via `@RdfProvides`
/// annotations in the parent class.
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
  /// not be registered automatically and must be provided via `@RdfProvides`
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
  /// final rdfMapper = initRdfMapper(userReferenceMapper);
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

/// Configures mapping details for IRI terms in RDF at the property level.
///
/// This class is used within the `@RdfProperty` annotation to customize how objects
/// are serialized as IRI terms in RDF. Unlike class-level mappings configured with
/// `@RdfIri`, these mappings are scoped to the specific property where they
/// are defined and are not registered globally.
///
/// In RDF, IRIs (Internationalized Resource Identifiers) are used to uniquely identify 
/// resources and properties. This mapping is ideal for:
///
/// - Properties representing identifiers that need custom formatting as IRIs
/// - References to other resources with specific IRI patterns
/// - Properties that must be serialized as IRIs rather than literals
/// - Customizing resource references for specific relationship contexts
///
/// **Important**: Mappers configured through `IriMapping` are only used by
/// the specific `ResourceMapper` whose property annotation references them. They are
/// not registered in the global mapper registry and won't be available for use by
/// other mappers or for direct lookup.
///
/// ## Property Type Support
///
/// The default constructor (`IriMapping([template])`) only supports `String` properties.
/// For non-String types like value objects (e.g., `UserId` or `ISBN` classes), you have
/// two options:
///
/// 1. Use one of the mapper constructors:
///    - `.namedMapper()` - Reference a named mapper provided at runtime
///    - `.mapper()` - Instantiate a mapper from a type
///    - `.mapperInstance()` - Use a pre-configured mapper instance
///
/// 2. Annotate the class of the property value with `@RdfIri` and implement the
///    template logic based on fields of that class there. This approach leverages
///    automatic mapper registration and is often cleaner when the value class
///    is fully under your control.
///
/// These approaches ensure proper serialization and deserialization for complex types.
///
/// ## Examples
///
/// For String properties:
/// ```dart
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('https://example.org/users/{userId}')
/// )
/// final String userId;
/// ```
///
/// For value objects:
/// ```dart
/// @RdfProperty(
///   SchemaPerson.identifier,
///   iri: IriMapping.mapper(UserIdMapper)
/// )
/// final UserId userId;
/// ```
/// 
/// Without this override, the property would use the default mapper registered for
/// the value class, which might be configured with `@RdfIri` at the class level.
/// The key difference is that the class-level mapper is globally registered (unless
/// `registerGlobally: false` is specified), while this property-level mapping is
/// only used for this specific property.
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
  ///
  /// **Note:** When using the default constructor with a template, the property must be of type
  /// `String`. For non-String types like value objects (e.g., `UserId`), either:
  /// 1. Use one of the mapper constructors (`.namedMapper()`, `.mapper()`, or `.mapperInstance()`)
  ///    to provide explicit conversion logic, or
  /// 2. Annotate the value class itself with `@RdfIri` and implement the template logic there.
  final String? template;

  /// Creates an IRI mapping template for property-specific IRI generation.
  ///
  /// Use this constructor to customize how a specific property should be
  /// transformed into an IRI term in the RDF graph.
  ///
  /// **Important:** This constructor is only designed for properties of type `String`.
  /// For non-String types (like value objects or domain-specific types), you have two options:
  /// 1. Use one of the mapper constructors: `.namedMapper()`, `.mapper()`, or `.mapperInstance()`
  /// 2. Annotate the value class itself with `@RdfIri` and implement the template logic there
  ///
  /// The [template] defines the pattern for constructing IRIs from the property value:
  /// - With a template: `IriMapping('http://example.org/users/{value}')`
  /// - Without a template: `IriMapping()` - uses the property value directly as the IRI
  ///
  /// This is particularly useful when the property contains identifier information
  /// that needs to be formatted in a specific way to create valid IRIs.
  ///
  /// Examples:
  /// ```dart
  /// // For String properties - using template is fine:
  /// @RdfProperty(
  ///   Dcterms.source,
  ///   iri: IriMapping('urn:isbn:{isbn}')
  /// )
  /// final String isbn; // Will be mapped to an IRI like "urn:isbn:9780123456789"
  ///
  /// // Option 1: For value types - use custom mapper:
  /// @RdfProperty(
  ///   SchemaPerson.identifier,
  ///   iri: IriMapping.mapper(UserIdMapper)
  /// )
  /// final UserId userId; // Will use UserIdMapper for conversion
  ///
  /// // Option 2: For value types - annotate the value class with @RdfIri:
  /// @RdfProperty(SchemaPerson.identifier)
  /// final UserId userId; // The UserId class is annotated with @RdfIri
  ///
  /// // Definition of the UserId class:
  /// @RdfIri('https://example.org/users/{value}')
  /// class UserId {
  ///   @RdfIriPart()
  ///   final String value;
  ///
  ///   UserId(this.value);
  /// }
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
  /// The [name] will correspond to a parameter in the generated `initRdfMapper` function,
  /// but the mapper will *not* be registered globally in the `RdfMapper` instance
  /// but only used for the Resource Mapper whose property is annotated with this mapping.
  ///
  /// This approach is particularly useful for IRIs that require complex logic or
  /// external context (like base URLs) that might vary between deployments.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom mapper for a UserReference object
  ///   @RdfProperty(
  ///     SchemaPerson.identifier,
  ///     iri: IriMapping.namedMapper('userReferenceMapper')
  ///   )
  ///   final UserReference userRef;
  /// }
  ///
  /// // You must implement the mapper:
  /// class UserReferenceMapper implements IriTermMapper<UserReference> {
  ///   @override
  ///   IriTerm toRdfTerm(UserReference value, SerializationContext context) {
  ///     return IriTerm('https://example.org/users/${value.username}');
  ///   }
  ///
  ///   @override
  ///   UserReference fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final segments = Uri.parse(term.iri).pathSegments;
  ///     return UserReference(segments.last);
  ///   }
  /// }
  ///
  /// // In initialization code:
  /// final userRefMapper = UserReferenceMapper();
  /// final rdfMapper = initRdfMapper(userReferenceMapper: userRefMapper);
  /// ```
  const IriMapping.namedMapper(String name)
      : template = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper` and it must have a 
  /// no-argument default constructor.
  ///
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping, 
  /// not automatically be registered globally.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom mapper for an ISBN object
  ///   @RdfProperty(
  ///     Dcterms.source,
  ///     iri: IriMapping.mapper(IsbnMapper)
  ///   )
  ///   final ISBN isbn;
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class IsbnMapper implements IriTermMapper<ISBN> {
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
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping, 
  /// not automatically be registered globally.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const catalogMapper = ProductCatalogMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// class Book {
  ///   // Using a custom pre-configured mapper for a product reference
  ///   @RdfProperty(
  ///     Schema.product,
  ///     iri: IriMapping.mapperInstance(catalogMapper)
  ///   )
  ///   final ProductReference product;
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
/// ## IRI Template Variables
/// The IRI template supports two types of variables:
///
/// 1. **Property-based variables** - Values from properties marked with `@RdfIriPart`:
///    ```dart
///    @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/books/{isbn}'))
///    class Book {
///      @RdfIriPart('isbn')  // Maps to {isbn} in the template
///      final String isbn;
///      // ...
///    }
///    ```
///
/// 2. **Context variables** - Values provided externally:
///    ```dart
///    @RdfGlobalResource(
///      SchemaBook.classIri,
///      IriStrategy('{baseUrl}/books/{id}')  // {baseUrl} is a context variable
///    )
///    class Book {
///      @RdfIriPart('id')
///      final String id;
///      // ...
///    }
///
///    // When registerGlobally is true (default):
///    final rdfMapper = initRdfMapper(
///      baseUrlProvider: () => 'https://myapp.example.org'  // Auto-injected parameter
///    );
///    ```
///
/// ## Context Variable Resolution
///
/// When the generator encounters template variables that aren't bound to properties with
/// `@RdfIriPart`, it treats them as context variables and resolves them in the following ways:
///
/// 1. **Global Registration** (when `registerGlobally = true` in `@RdfGlobalResource`, which is the default):
///    - The generator adds required provider parameters to `initRdfMapper()`
///    - These providers must be supplied when initializing the RDF mapper
///    - Example: `{baseUrl}` becomes `required String Function() baseUrlProvider`
///
/// 2. **Local Resolution** (when `registerGlobally = false`):
///    - The parent mapper that uses this type needs to provide the context values
///    - Context variables can be resolved from:
///      a. Properties in the parent class annotated with `@RdfProvides('variableName')`
///      b. Or required in the parent mapper's constructor (which may propagate up to `initRdfMapper`)
///
/// This system enables flexible, context-aware IRI patterns that can adapt to different
/// deployment environments without hardcoding values. Unlike the `RdfIri` annotation which is used
/// for classes that represent IRI terms themselves, `IriStrategy` is used within `RdfGlobalResource`
/// to define how instance IRIs are constructed from their properties.
///
/// ## Internal Record-Based Mechanism
///
/// Unlike `RdfIri` and `IriMapping` which work with complete objects, `IriStrategy` operates
/// on a record composed of the values from properties marked with `@RdfIriPart`. This
/// record-based approach allows resource mappers to:
///
/// 1. Extract only the necessary IRI-related properties when serializing
/// 2. Populate these same properties when deserializing from an IRI term
///
///
/// ## Constructor Choice and RdfIriPart Usage
///
/// * **Default constructor**: The generator creates an `IriTermMapper` implementation that
///   handles mapping between a record of the `@RdfIriPart` values and IRI terms. With this
///   approach, you can use the standard `@RdfIriPart([name])` constructor.
///
/// * **Custom mappers** (via `.namedMapper()`, `.mapper()`, or `.mapperInstance()`): You must
///   implement an `IriTermMapper` that works with a record of the property values. For multiple
///   `@RdfIriPart` properties, use `@RdfIriPart.position(index, [name])` to specify the
///   positional order of fields in the record for more robustness and to avoid bugs introduced by
///   changing field order.
///
class IriStrategy extends BaseMapping<IriTermMapper> {
  /// An optional template string for constructing IRIs from resource properties.
  ///
  /// The template can contain static text combined with variables in curly braces (`{variable}`).
  /// Variables are resolved in the following order:
  ///
  /// 1. **Class property variables**: Bound to properties marked with `@RdfIriPart`
  ///    - Example: `IriStrategy('urn:isbn:{isbn}')` where `{isbn}` is replaced with
  ///      the value of a property marked with `@RdfIriPart('isbn')`
  ///    - Multiple properties can be combined: `{baseUrl}/users/{userId}/profiles/{profileId}`
  ///
  /// 2. **Context variables**: Any variable not bound to a property (e.g., `{baseUri}`)
  ///    - When used with `registerGlobally = true` (default):
  ///      - The generator adds provider parameters to `initRdfMapper`
  ///      - Example: `{baseUri}` creates `required baseUriProvider: () => 'https://example.org'`
  ///    - When used with `registerGlobally = false`:
  ///      - The mapper looks for:
  ///        - Properties in the parent class with `@RdfProvides('variableName')`
  ///        - Or adds the provider as a required constructor parameter
  ///
  /// If no template is provided (`template == null`), the property marked with `@RdfIriPart`
  /// will be used directly as the complete IRI value.
  final String? template;

  /// Creates a strategy for generating IRIs from resource properties.
  ///
  /// Use this constructor with `@RdfGlobalResource` to have the generator create
  /// an IRI mapper automatically. The generator will:
  ///
  /// 1. Create a record type from all properties marked with `@RdfIriPart`
  /// 2. Generate an `IriTermMapper<RecordType>` implementation
  /// 3. Extract values from the resource into this record during serialization
  /// 4. Set properties in the resource from the record during deserialization
  ///    (unless they are also annotated with `@RdfProperty`, in which case the
  ///     value from @RdfProperty takes precedence)
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(
  ///   Person.classIri,
  ///   IriStrategy('{baseUri}/people/{id}')
  /// )
  /// class Person {
  ///   @RdfIriPart('id')  // Standard form works with generated mappers
  ///   final String id;
  ///   // ...
  /// }
  /// ```
  ///
  /// When the [template] contains unbound variables (not matching any property with `@RdfIriPart`),
  /// the generator will automatically create provider parameters. With `registerGlobally = true`
  /// (the default), these providers become required parameters in the `initRdfMapper` function.
  const IriStrategy([this.template]) : super();

  /// Creates a reference to a named mapper for this IRI strategy.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. With this approach, you must:
  /// 1. Implement the mapper yourself that works with a **record type**
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// Note that - unlike similar constructors like `RdfIri.namedMapper` - the
  /// named mapper will not be registered globally, it will only be used
  /// for the class annotated with `@RdfGlobalResource`.
  ///
  /// Unlike the default constructor which generates a mapper, this requires you to
  /// implement a mapper that works with a record of the property values from fields
  /// marked with `@RdfIriPart`.
  ///
  /// **Important:** When using custom mappers with multiple IRI part properties,
  /// use `@RdfIriPart.position(index)` to specify the order of fields in the record:
  ///
  /// ```dart
  /// @RdfGlobalResource(Product.classIri, IriStrategy.namedMapper('productIdMapper'))
  /// class Product {
  ///   @RdfIriPart.position(1) // First field in the record
  ///   final String category;
  ///
  ///   @RdfIriPart.position(2) // Second field in the record
  ///   final String id;
  ///   // ...
  /// }
  ///
  /// // Implement mapper for the (String, String) record:
  /// class ProductIdMapper implements IriTermMapper<(String, String)> {
  ///   @override
  ///   IriTerm toRdfTerm((String, String) record, SerializationContext context) {
  ///     final (category, id) = record;
  ///     return IriTerm('https://example.org/products/$category/$id');
  ///   }
  ///
  ///   @override
  ///   (String, String) fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final parts = term.iri.split('/').takeLast(2).toList();
  ///     return (parts[0], parts[1]);
  ///   }
  /// }
  ///
  /// // In initialization code:
  /// final productMapper = ProductIdMapper();
  /// final rdfMapper = initRdfMapper(productIdMapper: productMapper);
  /// ```
  ///
  /// The resource mapper will:
  /// - During serialization: Extract the properties into a record to pass to your mapper
  /// - During deserialization: Take the record your mapper produces and set the properties
  const IriStrategy.namedMapper(String name)
      : template = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper` for a **record type**
  /// composed of the `@RdfIriPart` property values.
  ///
  /// Note that - unlike similar constructors like `RdfIri.namedMapper` - the
  /// mapper will not be registered globally, it will only be used
  /// for the class annotated with `@RdfGlobalResource`.
  ///
  /// When implementing the mapper for multiple IRI parts, use `@RdfIriPart.position(index)`
  /// to define the position of each property in the record that will be passed to your mapper.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(Product.classIri, IriStrategy.mapper(ProductIdMapper))
  /// class Product {
  ///   @RdfIriPart.position(1) // First field in record
  ///   final String category;
  ///
  ///   @RdfIriPart.position(2) // Second field in record
  ///   final String id;
  ///   // ...
  /// }
  ///
  /// // Mapper must work with the record type defined by the RdfIriPart positions:
  /// class ProductIdMapper implements IriTermMapper<(String, String)> {
  ///   @override
  ///   IriTerm toRdfTerm((String, String) record, SerializationContext context) {
  ///     final (category, id) = record;
  ///     return IriTerm('https://example.org/products/$category/$id');
  ///   }
  ///
  ///   @override
  ///   (String, String) fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final parts = term.iri.split('/').takeLast(2).toList();
  ///     return (parts[0], parts[1]);
  ///   }
  /// }
  /// ```
  const IriStrategy.mapper(Type mapperType)
      : template = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// that works with a **record type** composed of the values from properties marked
  /// with `@RdfIriPart`. Unlike `RdfIri` and `IriMapping` which work with whole objects,
  /// `IriStrategy` mappers must work with records of property values.
  ///
  /// For multiple IRI parts, use `@RdfIriPart.position(index)` to specify the order
  /// of each property in the record:
  ///
  /// ```dart
  /// // Create a pre-configured mapper for a record type:
  /// const productMapper = CustomProductMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// @RdfGlobalResource(Product.classIri, IriStrategy.mapperInstance(productMapper))
  /// class Product {
  ///   // First field in the record passed to productMapper
  ///   @RdfIriPart.position(0)
  ///   final String category;
  ///
  ///   // Second field in the record passed to productMapper
  ///   @RdfIriPart.position(1)
  ///   final String sku;
  ///   // ...
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
/// ## Supported Property Types
///
/// This annotation works with:
///
/// - **Instance fields**: Compatible with all type-annotated fields (mutable, `final`, and `late`)
/// - **Getters and setters**: Both getter and setter must be provided.
/// - **Only public properties**: Private properties (with underscore prefix) are not supported.
///
/// For classes with `@RdfIri` (or indirectly with @IriMapping), all properties necessary for complete serialization/deserialization
/// must be annotated with `@RdfIriPart`. The instance must be fully reconstructable from just
/// these annotated properties.
///
/// ## Usage with IriStrategy
///
/// The annotation has different usage patterns depending on the `IriStrategy` constructor:
///
/// * With the **default constructor** (`IriStrategy(template)`), use the standard form
///   `@RdfIriPart([name])` - the generator handles record creation automatically.
///
/// * With **custom mappers** (`IriStrategy.namedMapper()`, `.mapper()`, or `.mapperInstance()`),
///   use `@RdfIriPart.position(index, [name])` for multiple properties to ensure
///   correct positioning in the record passed to your mapper.
///
/// ## Examples
///
/// Example with named template variable (generated mapper):
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
/// Example with positional parts for custom mappers:
/// ```dart
/// @RdfGlobalResource(
///   Product.classIri,
///   IriStrategy.namedMapper('productIdMapper')
/// )
/// class Product {
///   @RdfIriPart.position(1) // First position in the generated record type
///   final String category;
///
///   @RdfIriPart.position(2) // Second position in the generated record type
///   final String id;
///   // ...
/// }
/// ```
class RdfIriPart implements RdfAnnotation {
  /// The name of the IRI part. This corresponds to a named template variable
  /// in the `RdfIri` template (e.g., `id` for `{id}`).
  final String? name;

  /// The positional index of the IRI part, used when the IRI is constructed
  /// from multiple unnamed parts, typically for record types in custom mappers.
  ///
  /// Starts from 1 for the first part, 2 for the second, and so on - in sync
  /// with the `.$1`, `.$2` syntax for accessing the first, second etc.
  /// part of a record.
  final int? pos;

  /// Creates an IRI part annotation with a given [name].
  const RdfIriPart([this.name]) : pos = null;

  /// Creates an IRI part annotation with a given [position].
  const RdfIriPart.position(int position, [this.name]) : pos = position;
}
