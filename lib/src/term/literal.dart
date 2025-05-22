import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a Dart class as representing an RDF literal term.
///
/// This annotation is used for value types that need custom serialization beyond simple
/// Dart primitives:
///
/// - Value objects with validation logic (e.g., ratings, percentages, identifiers)
/// - Objects with formatted string representations (e.g., temperatures, currencies)
/// - Custom types with specific RDF serialization requirements
///
/// When you annotate a class with `@RdfLiteral`, a mapper is created that handles
/// the conversion between your Dart class and RDF literal values.
///
/// ## Usage Options
///
/// You can define how your class is mapped in several ways:
///
/// 1. **Simple value objects** - Use `@RdfLiteral()` and mark a property with `@RdfValue()`
/// 2. **Custom conversion methods** - Use `@RdfLiteral.custom()` and specify class methods
/// 3. **External mappers** - Use `.namedMapper()`, `.mapper()`, or `.mapperInstance()`
///
/// ## Property-Level Usage
///
/// You can also apply this as part of an `@RdfProperty` annotation to override
/// serialization for a specific property:
///
/// ```dart
/// @RdfProperty(
///   SchemaBook.price,
///   literal: LiteralMapping.namedMapper('priceMapper')
/// )
/// final Price price;
/// ```
///
/// ## Examples
///
/// **Simple value with validation:**
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // Value to use for serialization
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
/// **Custom conversion methods:**
/// ```dart
/// @RdfLiteral.custom(
///   toLiteralTermMethod: 'formatCelsius',
///   fromLiteralTermMethod: 'parse',
/// )
/// class Temperature {
///   final double celsius;
///   Temperature(this.celsius);
///
///   LiteralTerm formatCelsius() => LiteralTerm('$celsius°C');
///
///   static Temperature parse(LiteralTerm term) =>
///     Temperature(double.parse(term.value.replaceAll('°C', '')));
/// }
/// ```
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
class RdfLiteral extends BaseMappingAnnotation<LiteralTermMapper>
    implements RdfAnnotation {
  /// Optional method name to use for converting the object to a [LiteralTerm].
  ///
  /// This method must be an instance method on the annotated class that returns a
  /// [LiteralTerm]. If not specified, the generator will look for a property marked
  /// with `@RdfValue` and use its value for conversion.
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

  final IriTerm? datatype;

  /// Creates an annotation for a class to be mapped to a literal term.
  ///
  /// This standard constructor creates a mapper that automatically handles the
  /// conversion between your class and an RDF literal term. It works by:
  ///
  /// 1. Looking for a property in your class marked with `@RdfValue`
  /// 2. Using that property to create a literal value during serialization
  /// 3. Using that property's type and the constructor to deserialize values
  ///
  /// This is the simplest approach for value objects that wrap a single literal value.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral()
  /// class Rating {
  ///   @RdfValue() // Marks this property as the source for the literal value
  ///   final int stars;
  ///
  ///   Rating(this.stars) {
  ///     if (stars < 0 || stars > 5) {
  ///       throw ArgumentError('Rating must be between 0 and 5 stars');
  ///     }
  ///   }
  /// }
  /// ```
  const RdfLiteral([this.datatype])
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        super(registerGlobally: true);

  /// Creates an annotation for a class using custom methods for literal conversion.
  ///
  /// This approach allows you to define how your class is converted to/from RDF literals
  /// by specifying methods in your class:
  ///
  /// * [toLiteralTermMethod]: An instance method that converts your object to a `String`
  /// * [fromLiteralTermMethod]: A static method that creates your object from a `String`
  ///
  /// This is ideal for classes that need special formatting or validation during
  /// serialization, such as formatted values with specific string representations
  /// (temperatures, currencies, structured values, etc.).
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.custom(
  ///   toLiteralTermMethod: 'formatCelsius',
  ///   fromLiteralTermMethod: 'parse',
  /// )
  /// class Temperature {
  ///   final double celsius;
  ///
  ///   Temperature(this.celsius);
  ///
  ///   // Instance method for serialization
  ///   String formatCelsius() => '$celsius°C';
  ///
  ///   // Static method for deserialization
  ///   static Temperature parse(String value) =>
  ///     Temperature(double.parse(value.replaceAll('°C', '')));
  /// }
  /// ```
  const RdfLiteral.custom(
      {this.datatype,
      required String toLiteralTermMethod,
      required String fromLiteralTermMethod})
      : toLiteralTermMethod = toLiteralTermMethod,
        fromLiteralTermMethod = fromLiteralTermMethod,
        super();

  /// Creates a reference to a named mapper for this literal term.
  ///
  /// This constructor is used when you want to provide a custom `LiteralTermMapper`
  /// implementation for this class via dependency injection. When using this
  /// approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will correspond to a parameter in the generated `initRdfMapper`
  /// function.
  ///
  /// This approach is particularly useful for complex value objects that require
  /// special serialization logic or context-dependent conversions.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.namedMapper('temperatureMapper')
  /// class Temperature {
  ///   final double celsius;
  ///   Temperature(this.celsius);
  ///   // ...
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyTemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final tempMapper = MyTemperatureMapper();
  /// initRdfMapper({required LiteralTermMapper<Temperature> temperatureMapper: tempMapper}) { ... }
  /// ```
  const RdfLiteral.namedMapper(String name)
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        datatype = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle literal
  /// term mapping for this class. The type must implement `LiteralTermMapper<T>`
  /// where T is the annotated class.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.mapper(TemperatureMapper)
  /// class Temperature {
  ///   final double celsius;
  ///   Temperature(this.celsius);
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class TemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   @override
  ///   LiteralTerm toRdfTerm(Temperature temp, SerializationContext context) {
  ///     return LiteralTerm('${temp.celsius}°C');
  ///   }
  ///
  ///   @override
  ///   Temperature fromRdfTerm(LiteralTerm term, DeserializationContext context) {
  ///     return Temperature(double.parse(term.value.replaceAll('°C', '')));
  ///   }
  /// }
  /// ```
  const RdfLiteral.mapper(Type mapperType)
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        datatype = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this literal
  /// term.
  ///
  /// This allows you to supply a pre-existing instance of a `LiteralTermMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// This is the most direct method for providing custom serialization logic,
  /// especially when the mapper needs configuration or context from the
  /// application.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const tempMapper = TemperatureMapper(
  ///   unit: TemperatureUnit.celsius,
  ///   precision: 2,
  ///   locale: 'en_US',
  /// );
  ///
  /// @RdfLiteral.mapperInstance(tempMapper)
  /// class Temperature {
  ///   final double value;
  ///   Temperature(this.value);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfLiteral.mapperInstance(LiteralTermMapper instance)
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        datatype = null,
        super.mapperInstance(instance);
}

/// Configures mapping details for literal values in RDF.
///
/// This class is used within the `@RdfProperty` annotation to customize how objects
/// are serialized as literal values in RDF, allowing property-specific mapping behavior
/// that overrides the class-level configuration defined with `@RdfLiteral`.
///
/// In RDF, literal values represent simple data values like strings, numbers, or dates.
/// This mapping is typically used for:
///
/// - Value objects with special formatting requirements
/// - Custom data types that need specialized serialization logic
/// - Properties that need different literal representation than their default type
/// - Context-specific formatting (e.g., currencies that need different formats in different contexts)
///
/// Example:
/// ```dart
/// @RdfProperty(
///   SchemaBook.price,
///   literal: LiteralMapping.namedMapper('formattedPriceMapper')
/// )
/// final Price price;
/// ```
class LiteralMapping extends BaseMapping<LiteralTermMapper> {
  final String? language;
  final IriTerm? datatype;

  /// Creates a reference to a named mapper for this literal term.
  ///
  /// This constructor is used when you want to provide a custom `LiteralTermMapper`
  /// implementation for this class via dependency injection. When using this
  /// approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will correspond to a parameter in the generated `initRdfMapper`
  /// function.
  ///
  /// This approach is particularly useful for complex value objects that require
  /// special serialization logic or context-dependent conversions.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.namedMapper('temperatureMapper')
  /// class Temperature {
  ///   final double celsius;
  ///   Temperature(this.celsius);
  ///   // ...
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyTemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final tempMapper = MyTemperatureMapper();
  /// initRdfMapper({required LiteralTermMapper<Temperature> temperatureMapper: tempMapper}) { ... }
  /// ```
  const LiteralMapping.namedMapper(String name)
      : language = null,
        datatype = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle literal
  /// term mapping for this class. The type must implement `LiteralTermMapper<T>`
  /// where T is the annotated class.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.mapper(TemperatureMapper)
  /// class Temperature {
  ///   final double celsius;
  ///   Temperature(this.celsius);
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class TemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   @override
  ///   LiteralTerm toRdfTerm(Temperature temp, SerializationContext context) {
  ///     return LiteralTerm('${temp.celsius}°C');
  ///   }
  ///
  ///   @override
  ///   Temperature fromRdfTerm(LiteralTerm term, DeserializationContext context) {
  ///     return Temperature(double.parse(term.value.replaceAll('°C', '')));
  ///   }
  /// }
  /// ```
  const LiteralMapping.mapper(Type mapperType)
      : language = null,
        datatype = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this literal
  /// term.
  ///
  /// This allows you to supply a pre-existing instance of a `LiteralTermMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// This is the most direct method for providing custom serialization logic,
  /// especially when the mapper needs configuration or context from the
  /// application.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const tempMapper = TemperatureMapper(
  ///   unit: TemperatureUnit.celsius,
  ///   precision: 2,
  ///   locale: 'en_US',
  /// );
  ///
  /// @RdfLiteral.mapperInstance(tempMapper)
  /// class Temperature {
  ///   final double value;
  ///   Temperature(this.value);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const LiteralMapping.mapperInstance(LiteralTermMapper instance)
      : language = null,
        datatype = null,
        super.mapperInstance(instance);

  /// Specifies a language tag for string literals.
  ///
  /// This constructor creates a mapping that will apply the given language tag
  /// to string values when serialized as RDF literals. This is particularly useful
  /// for human-readable text that appears in a specific language.
  ///
  /// The [language] parameter must be a valid BCP47 language tag (e.g., 'en', 'de-DE').
  ///
  /// Example:
  /// ```dart
  /// @RdfProperty(
  ///   SchemaBook.description,
  ///   literal: LiteralMapping.withLanguage('en')
  /// )
  /// final String description; // Will be serialized as "description"@en
  /// ```
  ///
  /// Note: While language tags are primarily intended for string properties, this constructor
  /// can also be used with non-string properties. In such cases, the mapper first converts
  /// the value to a string representation using the appropriate registered mapper, then
  /// applies the language tag to the resulting string literal. This makes it ideal for use
  /// with custom value types that essentially wrap a string, such as translated content,
  /// descriptions, or any text that should be associated with a specific language.
  const LiteralMapping.withLanguage(String language)
      : language = language,
        datatype = null,
        super();

  /// Specifies a custom datatype for literal values.
  ///
  /// This constructor creates a mapping that will apply the given datatype IRI
  /// to values when serialized as RDF literals. This is useful when you need to
  /// explicitly set the datatype of a literal, overriding the default datatype
  /// that would be inferred from the Dart type.
  ///
  /// The [datatype] parameter must be an `IriTerm` representing the IRI of the RDF datatype.
  /// Well-known datatypes are available as constants in the Xsd class in the
  /// `rdf_vocabularies` package. For example:
  /// - Xsd.string
  /// - Xsd.integer
  /// - Xsd.decimal
  /// - Xsd.boolean
  /// - Xsd.date
  /// - Xsd.time
  ///
  /// Example:
  /// ```dart
  /// @RdfProperty(
  ///   SchemaBook.publicationYear,
  ///   literal: LiteralMapping.withType(Xsd.gYear)
  /// )
  /// final int year; // Will be serialized with a specific year datatype
  /// ```
  ///
  /// Note: This constructor can be used with both string and non-string properties. For non-string
  /// properties, the mapper first converts the value to a string representation using the
  /// appropriate registered mapper for the property's type, then applies the custom datatype
  /// to the resulting string literal. This allows you to use custom datatypes with any property
  /// type that has a registered mapper, while preserving the semantics of the original value.
  const LiteralMapping.withType(IriTerm datatype)
      : language = null,
        datatype = datatype,
        super();
}

/// Marks a property within a class as the primary value source for RDF literal
/// conversion.
///
/// This annotation is used within classes annotated with `@RdfLiteral`
/// to designate which property provides the value for RDF literal serialization.
/// The generator automatically detects the appropriate datatype from the
/// property's type.
///
/// When the generator creates a `LiteralTermMapper` for a class marked with
/// `@RdfLiteral()`, it uses the property marked with `@RdfValue()` as the source
/// of the literal value. This means that only this property's value will be
/// included in the RDF serialization,
/// while other properties in the class are used only within the Dart application.
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
/// Used within `@RdfLiteral` annotated classes to specify a property that provides
/// the language tag for language-tagged string literals (e.g., "Hello"@en). Only one
/// property per class should be annotated with `@RdfLanguageTag`, and it must be of
/// type `String`.
///
/// Language tags are a crucial feature of RDF literals, particularly for
/// human-readable text in different languages. When a class has both `@RdfValue`
/// and `@RdfLanguageTag` annotations, the generator creates a mapper that produces
/// language-tagged literals in the RDF graph.
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
