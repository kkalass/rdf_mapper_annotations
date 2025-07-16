# RDF Mapper Annotations for Dart

> **🎯 Code Generation Now Available**  
> This library provides the annotation system for mapping Dart objects to RDF graphs. Use it with the `rdf_mapper_generator` package (v0.2.1+) to automatically generate type-safe mapping code from your annotated classes.

[![pub package](https://img.shields.io/pub/v/rdf_mapper_annotations.svg)](https://pub.dev/packages/rdf_mapper_annotations)
[![build](https://github.com/kkalass/rdf_mapper_annotations/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_mapper_annotations/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_mapper_annotations/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_mapper_annotations)
[![license](https://img.shields.io/github/license/kkalass/rdf_mapper_annotations.svg)](https://github.com/kkalass/rdf_mapper_annotations/blob/main/LICENSE)

A powerful, declarative annotation system for seamless mapping between Dart objects and RDF graphs.

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_mapper_annotations/)

`rdf_mapper_annotations` provides the annotation system for declaring how to map between Dart objects and RDF data, similar to how an ORM works for databases. These annotations are processed by the `rdf_mapper_generator` package to generate the actual mapping code at build time.

**To use these annotations:**
1. Annotate your Dart classes with the provided RDF annotations
2. Run the `rdf_mapper_generator` code generator to create mapping code
3. Use the generated mappers to serialize/deserialize between Dart objects and RDF formats

With this declarative approach, you can define how your domain model maps to RDF without writing boilerplate serialization code.

### Key Features

- **Declarative annotations** for clean, maintainable code
- **Type-safe mapping** between Dart classes and RDF resources
- **Support for code generation** (via rdf_mapper_generator)
- **Lossless RDF mapping** with `@RdfUnmappedTriples` for perfect round-trip preservation
- **Flexible IRI generation strategies** for resource identification
- **Comprehensive collection support** for lists, sets, and maps
- **Native enum support** with custom values and IRI templates
- **Extensible architecture** through custom mappers

## Part of a Family of Projects

This library is part of a comprehensive ecosystem for working with RDF in Dart:

* [rdf_core](https://github.com/kkalass/rdf_core) - Core graph classes and serialization (Turtle, JSON-LD, N-Triples)
* [rdf_mapper](https://github.com/kkalass/rdf_mapper) - Base mapping system between Dart objects and RDF
* [rdf_mapper_generator](https://github.com/kkalass/rdf_mapper_generator) - Code generator for this annotation library
* [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies) - Constants for common RDF vocabularies (Schema.org, FOAF, etc.)
* [rdf_xml](https://github.com/kkalass/rdf_xml) - RDF/XML format support
* [rdf_vocabulary_to_dart](https://github.com/kkalass/rdf_vocabulary_to_dart) - Generate constants for custom vocabularies

## What is RDF?

[Resource Description Framework (RDF)](https://www.w3.org/RDF/) is a standard model for data interchange on the Web. RDF represents information as simple statements in the form of subject-predicate-object triples. This library lets you work with RDF data using familiar Dart objects without needing to manage triples directly.

### Key RDF Terms

To better understand this library, it's helpful to know these core RDF concepts:

- **IRI** (International Resource Identifier): A unique web address that identifies a resource (similar to a URL but more flexible). In RDF, IRIs serve as global identifiers for things.

- **Triple**: The basic data unit in RDF, composed of subject-predicate-object. For example: "Book123 (subject) has-author (predicate) Person456 (object)".

- **Literal**: A simple data value like a string, number, or date that appears as an object in a triple.

- **Blank Node**: An anonymous resource that exists only in the context of other resources.

- **Subject**: The resource a triple is describing (always an IRI or blank node).

- **Predicate**: The property or relationship between the subject and object (always an IRI).

- **Object**: The value or resource that relates to the subject (can be an IRI, blank node, or literal).

## Quick Start

**Prerequisites:** This library requires the `rdf_mapper_generator` package to generate the actual mapping code from your annotations.

1. Add dependencies to your project:

```bash
# Add runtime dependencies
dart pub add rdf_core rdf_mapper rdf_mapper_annotations
dart pub add rdf_vocabularies  # Optional but recommended for standard vocabularies

# Add development dependencies (required for code generation)
dart pub add build_runner --dev
dart pub add rdf_mapper_generator --dev  # Version 0.2.1 or higher
```

2. Define your data model with RDF annotations:

```dart
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

@RdfGlobalResource(
  SchemaBook.classIri, 
  IriStrategy('http://example.org/book/{id}')
)
class Book {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/author/{authorId}')
  )
  final String authorId;

  @RdfProperty(SchemaBook.hasPart)
  final Iterable<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.authorId,
    required this.chapters,
  });
}

@RdfLocalResource(SchemaChapter.classIri)
class Chapter {
  @RdfProperty(SchemaChapter.name)
  final String title;

  @RdfProperty(SchemaChapter.position)
  final int number;

  Chapter(this.title, this.number);
}
```

3. **Generate the mapping code** using the `rdf_mapper_generator`:

```bash
# This command processes your annotations and generates the mapping code
dart run build_runner build --delete-conflicting-outputs
```

This will generate:
- A `rdf_mapper.g.dart` file with the initialization function
- Individual mapper files for each annotated class
- Type-safe serialization/deserialization code

4. Use the generated mappers:

```dart
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
// Import the generated mapper initialization file
import 'package:your_package/rdf_mapper.g.dart';

void main() {
  // Initialize the generated mapper
  final mapper = initRdfMapper();
  
  // Create a book with chapters
  final book = Book(
    id: '123',
    title: 'RDF Mapping with Dart',
    authorId: 'k42',  // Will be mapped to http://example.org/author/k42
    chapters: [
      Chapter('Getting Started', 1),
      Chapter('Advanced Mapping', 2),
    ],
  );
  
  // Convert to serialized format (Turtle, JSON-LD, etc.)
  final turtle = mapper.encodeObject(book);
  print(turtle);
  
  // Parse back to Dart object
  final parsedBook = mapper.decodeObject<Book>(turtle);
  print(parsedBook.title); // 'RDF Mapping with Dart'
}
```

## How It Works

This library follows a two-step process:

1. **Annotation Phase**: You annotate your Dart classes with RDF mapping annotations (this library)
2. **Code Generation Phase**: The `rdf_mapper_generator` analyzes your annotations and generates efficient mapping code

**Development Workflow:**
- Annotate your classes → Run `dart run build_runner build` → Use generated mappers
- When you change annotations → Re-run the build command → Updated mappers are ready to use

The generated code is type-safe, efficient, and handles all the RDF serialization/deserialization complexity for you.

## Key Concepts

### Class Annotations

- **@RdfGlobalResource**: For primary entities with globally unique web addresses (IRIs). These become the "subjects" in RDF triples.
- **@RdfLocalResource**: For child entities that only exist in relation to their parent. These become "blank nodes" in RDF.
- **@RdfIri**: For classes representing web addresses (IRIs), used when you need a custom type for IRIs.
- **@RdfLiteral**: For classes representing simple values like strings, numbers, or custom formats with validation.

### Property Annotations

- **@RdfProperty**: Maps a Dart class property to an RDF relation (predicate). Defines how properties connect to other resources.
- **@RdfIriPart**: Marks fields that help construct the resource's web address (IRI).
- **@RdfValue**: Identifies which field provides the actual data value for a literal.
- **@RdfMapEntry**: Specifies how key-value pairs are converted to RDF (since RDF has no native map concept).

### IRI Strategies

RDF Mapper provides flexible strategies for generating and parsing IRIs for resources. 

#### Simple Template-based IRIs

The most common approach uses a template with placeholders:

```dart
@RdfGlobalResource(
  Person.classIri, 
  IriStrategy('https://example.org/people/{id}')
)
class Person {
  @RdfIriPart()  // Will be substituted into {id} in the template
  final String id;
  
  // Other properties...
}
```

#### Direct IRI Storage

For cases when you want to store the full IRI in the object:

```dart
@RdfGlobalResource(
  SchemaPerson.classIri, 
  IriStrategy()  // Empty strategy means use the IRI field directly
)
class Person {
  @RdfIriPart()  // Contains the complete IRI
  final String iri;
  
  // Other properties...
}
```

#### Multi-part IRIs

For IRIs constructed from multiple fields:

```dart
@RdfGlobalResource(
  SchemaChapter.classIri,
  IriStrategy('https://example.org/books/{bookId}/chapters/{chapterNumber}')
)
class Chapter {
  @RdfIriPart()  // Maps to {bookId}
  final String bookId;
  
  @RdfIriPart("chapterNumber")  // Maps to {chapterNumber}
  final int number;
  
  // Other properties...
}
```

#### Globally Injected Placeholders

Use globally injected placeholders for values that should be provided at runtime:

```dart
// Define models with configurable base URIs
@RdfGlobalResource(
  SchemaPerson.classIri, 
  IriStrategy('{+baseUri}/persons/{id}')  // {baseUri} is not directly from a class field and is marked with +, thus matches including /
)
class Person {
  @RdfIriPart()
  final String id;
  
  @RdfProperty(SchemaPerson.name)
  final String name;
  
  Person({required this.id, required this.name});
}

@RdfGlobalResource(
  SchemaOrganization.classIri, 
  IriStrategy('{+baseUri}/organizations/{id}')  // Same placeholder across models
)
class Organization {
  @RdfIriPart()
  final String id;
  
  @RdfProperty(SchemaOrganization.name)
  final String name;
  
  Organization({required this.id, required this.name});
}

// At runtime, provide values for the global placeholders
void main() {
  // The generated initRdfMapper function will require providers for global placeholders
  final mapper = initRdfMapper(
    // Provide a function that returns the baseUri value
    baseUriProvider: () => 'https://user-specific-domain.com',
  );
  
  // Now when you create and serialize objects, the baseUri will be injected
  final person = Person(id: '123', name: 'Alice');
  final org = Organization(id: 'acme', name: 'ACME Inc.');
  
  // IRI will be: https://user-specific-domain.com/persons/123
  final personGraph = mapper.encodeObject(person);
  
  // IRI will be: https://user-specific-domain.com/organizations/acme
  final orgGraph = mapper.encodeObject(org);
}
```

This approach is particularly useful for:
- Multi-tenant applications where each tenant has their own domain
- Applications that need to switch between development/staging/production URLs
- Supporting user-specific or deployment-specific base URIs
- Maintaining a consistent IRI structure across your entire model

#### Custom Mapper for Complex Cases

When you need complete control over IRI generation and parsing:

```dart
@RdfGlobalResource(
  SchemaChapter.classIri,
  IriStrategy.namedMapper('chapterIdMapper')  // Reference to your custom mapper
)
class Chapter {
  @RdfIriPart.position(1)  // Position in the record type used by the mapper
  final String bookId;
  
  @RdfIriPart.position(2)  // Position matters for the record type
  final int chapterNumber;
  
  // Other properties...
}

// Your custom IRI mapper implementation
class ChapterIdMapper implements IriTermMapper<(String bookId, int chapterId)> {
  final String baseUrl;
  
  ChapterIdMapper({required this.baseUrl});
  
  @override
  IriTerm toRdfTerm((String, int) value, SerializationContext context) {
    return IriTerm('$baseUrl/books/${value.$1}/chapters/${value.$2}');
  }
  
  @override
  (String, int) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Parse the IRI and extract components
    final uri = Uri.parse(term.iri);
    final segments = uri.pathSegments;
    
    // Expected path: /books/{bookId}/chapters/{chapterId}
    if (segments.length >= 4 && segments[0] == 'books' && segments[2] == 'chapters') {
      return (segments[1], int.parse(segments[3]));
    }
    
    throw FormatException('Invalid Chapter IRI format: ${term.iri}');
  }
}
```

### IRI Property Mapping

When a property should reference another resource (rather than contain a literal value), use `IriMapping` to generate proper IRIs from simple values:

```dart
class Book {
  // Maps the string "k42" to the IRI "http://example.org/author/k42"
  @RdfProperty(
    SchemaBook.author,  // Expects an IRI to a Person
    iri: IriMapping('http://example.org/author/{authorId}')
  )
  final String authorId;
  
  // ...
}
```

This is especially valuable for:
- Referencing external resources with IRIs
- Creating semantic connections between objects
- Adhering to vocabulary specifications (like Schema.org)
- Maintaining proper RDF graph structure when a predicate expects an IRI rather than a literal

---

## Advanced Features

### Custom Types and Literals

Create custom types with specialized serialization:

```dart
@RdfLiteral()
class Rating {
  @RdfValue()
  final int stars;
  
  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',
  datatype: IriTerm.prevalidated('http://example.org/temperature')
)
class Temperature {
  final double celsius;
  
  Temperature(this.celsius);
  
  LiteralContent formatCelsius() => LiteralContent('$celsius°C');
  
  static Temperature parse(LiteralContent term) {
    return Temperature(double.parse(term.value.replaceAll('°C', '')));
  }
}
```

### Internationalization Support

Handle localized texts with language tags:

```dart
@RdfLiteral()
class LocalizedText {
  @RdfValue()
  final String text;
  
  @RdfLanguageTag()
  final String languageTag;
  
  LocalizedText(this.text, this.languageTag);
  
  // Convenience constructors
  LocalizedText.en(String text) : this(text, 'en');
  LocalizedText.de(String text) : this(text, 'de');
}
```

### Map Collections

RDF has no native concept of key-value pairs. This library provides two different approaches for mapping Map<K,V> collections:

#### 1. Using a dedicated entry class (Most common approach)

This approach uses a class with `@RdfMapKey` and `@RdfMapValue` annotations:

```dart
// In your main class
class Task {
  @RdfProperty(TaskVocab.vectorClock)
  @RdfMapEntry(VectorClockEntry)  // Specify the entry class
  Map<String, int> vectorClock;  // clientId → version number
}

// The entry class with key and value properties
@RdfLocalResource(VectorClockVocab.classIri)  
class VectorClockEntry {
  @RdfProperty(VectorClockVocab.clientId)
  @RdfMapKey()  // This property provides the Map key
  final String clientId;

  @RdfProperty(VectorClockVocab.clockValue)
  @RdfMapValue()  // This property provides the Map value 
  final int clockValue;

  VectorClockEntry(this.clientId, this.clockValue);
}
```

Each map entry is represented as a separate resource in the RDF graph with its own properties.

#### 2. Using a custom mapper (For special cases)

This approach handles map entries directly without separate resources:

```dart
// Direct mapping using a custom mapper
class Book {
  @RdfProperty(
    BookVocab.title,
    literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper())
  )
  final Map<String, String> translations;  // language → translated text
  
  Book({required this.translations});
}

// Custom mapper converts between Map entries and RDF literals
class LocalizedEntryMapper implements LiteralTermMapper<MapEntry<String, String>> {
  const LocalizedEntryMapper();

  @override
  MapEntry<String, String> fromRdfTerm(LiteralTerm term, DeserializationContext context) =>
    MapEntry(term.language ?? 'en', term.value);

  @override
  LiteralTerm toRdfTerm(MapEntry<String, String> value, SerializationContext context) =>
    LiteralTerm.withLanguage(value.value, value.key);
}
```

In this example, map entries are serialized as language-tagged literals, where the key becomes the language tag and the value becomes the literal value.

### Lossless RDF Mapping

Preserve all RDF data during serialization/deserialization cycles with lossless mapping features:

#### @RdfUnmappedTriples - Catch-All for Unknown Properties

Use `@RdfUnmappedTriples()` to capture any RDF properties that aren't explicitly mapped to other fields:

```dart
@RdfGlobalResource(SchemaPerson.classIri, IriStrategy("https://example.org/people/{id}"))
class Person {
  @RdfIriPart("id")
  final String id;

  @RdfProperty(SchemaPerson.name)
  final String name;

  // Captures email, telephone, and any other unmapped properties
  @RdfUnmappedTriples()
  final RdfGraph unmappedProperties;

  Person({required this.id, required this.name, RdfGraph? unmappedProperties})
    : unmappedProperties = unmappedProperties ?? RdfGraph(triples: []);
}
```

#### RdfGraph as Property Type

Use `RdfGraph` as a regular property type to capture structured subgraphs without creating custom classes:

```dart
class Person {
  @RdfProperty(SchemaPerson.name)
  final String name;

  // Captures address as a subgraph (streetAddress, city, postalCode, etc.)
  @RdfProperty(SchemaPerson.address)
  final RdfGraph? address;

  // Still preserves any other unmapped properties
  @RdfUnmappedTriples()
  final RdfGraph unmappedProperties;
}
```

#### Document-Level Lossless Workflow

For complete document preservation including unrelated entities, use the lossless methods:

```dart
// Decode with remainder - captures both object data and document-level unmapped data
final (person, remainderGraph) = mapper.decodeObjectLossless<Person>(turtle);

// person.unmappedProperties contains triples about the person that weren't mapped
// remainderGraph contains all other triples from the document (other entities, etc.)

// Encode back preserving everything - perfect round-trip
final restoredTurtle = mapper.encodeObjectLossless((person, remainderGraph));
```

**Benefits:**
- **Perfect round-trip preservation**: No data loss during Dart ↔ RDF conversion
- **Future-proof**: Handle evolving RDF schemas gracefully
- **Flexibility**: Mix strongly-typed properties with flexible graph storage
- **Document integrity**: Preserve entire RDF documents, not just individual objects

See `example/catch_all.dart` for a complete demonstration.

### Enum Support

RDF Mapper provides comprehensive support for mapping Dart enums to RDF literals and IRIs with type safety and custom serialization values.

#### Basic Enum Mapping

Use `@RdfLiteral` for enums that should serialize as literal values:

```dart
@RdfLiteral()
enum BookFormat {
  hardcover,  // → "hardcover"
  paperback,  // → "paperback"
  ebook,      // → "ebook"
}
```

Use `@RdfIri` with templates for enums that should serialize as IRIs:

```dart
@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  brandNew,     // → <http://schema.org/brandNew>
  used,         // → <http://schema.org/used>
  refurbished,  // → <http://schema.org/refurbished>
}
```

#### Custom Enum Values

Override individual enum constant serialization with `@RdfEnumValue`:

```dart
@RdfLiteral()
enum Priority {
  @RdfEnumValue('H')
  high,         // → "H"
  
  @RdfEnumValue('M')
  medium,       // → "M"
  
  @RdfEnumValue('L')
  low,          // → "L"
}

@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  @RdfEnumValue('NewCondition')
  brandNew,     // → <http://schema.org/NewCondition>
  
  @RdfEnumValue('UsedCondition')
  used,         // → <http://schema.org/UsedCondition>
  
  refurbished,  // → <http://schema.org/refurbished> (uses enum name)
}
```

#### Enum Integration with Resources

Enums work seamlessly with resource classes:

```dart
@RdfGlobalResource(BookVocab.classIri, IriStrategy('http://example.org/books/{id}'))
class Book {
  @RdfIriPart()
  final String id;

  @RdfProperty(BookVocab.format)
  final BookFormat format;  // Uses enum's @RdfLiteral mapping

  @RdfProperty(BookVocab.condition)
  final ItemCondition condition;  // Uses enum's @RdfIri mapping

  // Override with custom language tag for this property
  @RdfProperty(BookVocab.priority, literal: LiteralMapping.withLanguage('en'))
  final Priority priority;

  Book({required this.id, required this.format, required this.condition, required this.priority});
}
```

For detailed examples including advanced IRI templates with context variables, see the [Enum Mapping Guide](doc/enum_mapping_guide.md).

### Using Custom Mappers

For special cases, you can implement custom mappers alongside generated ones:

```dart
// Custom mapper implementation
class EventMapper implements GlobalResourceMapper<Event> {
  @override
  final IriTerm typeIri = EventVocab.classIri;
  
  @override
  RdfSubject toRdfResource(Event instance, SerializationContext context, {RdfSubject? parentSubject}) {
    // Custom serialization logic here
    return context.resourceBuilder(IriTerm('http://example.org/events/${instance.id}'))
      .addValue(EventVocab.timestamp, instance.timestamp)
      .addValues(instance.customData.entries.map(
        (e) => MapEntry(IriTerm('http://example.org/property/${e.key}'), e.value)))
      .build();
  }
  
  @override
  Event fromRdfResource(RdfSubject subject, DeserializationContext context) {
    // Custom deserialization logic here
    return Event(/* ... */);
  }
}

// Register your custom mapper with the system
final rdfMapper = initRdfMapper();
rdfMapper.registerMapper<Event>(EventMapper());

// Now use it alongside generated mappers
final eventGraph = rdfMapper.encodeObject(event);
```

## Best Practices

To get the most out of RDF Mapper:

- **Use standard vocabularies** - The `rdf_vocabularies` package provides ready-to-use constants for common vocabularies. Use the [online search tool](https://kkalass.github.io/rdf_vocabularies/api/index.html) to discover terms.

- **Choose the right resource type**:
  - `@RdfGlobalResource` for entities with independent identity
  - `@RdfLocalResource` for entities that only exist in context of a parent
  - `@RdfLiteral` for values you want to serialize as a primitive like String, int etc.
  - `@RdfIri` for IRI (similar to URL) reference values 

- **Model relationships correctly** - Use IRI mapping for references to other resources rather than string literals

## Learn More

For detailed examples and advanced topics:

- **[Enum Mapping Guide](doc/enum_mapping_guide.md)** - Comprehensive guide to enum support with examples
- **[Examples Directory](https://github.com/kkalass/rdf_mapper_annotations/tree/main/example)** - Complex mappings, vector clocks, IRI strategies, and more

## 🛣️ Roadmap / Next Steps

- Schema generating based on annotations, for example `@RdfProperty.schemaDefine('https://my.app.com/vocab/MyType/myProp')` or similar


## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_mapper_annotations/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
