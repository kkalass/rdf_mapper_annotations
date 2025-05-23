# RDF Mapper Annotations for Dart

[![pub package](https://img.shields.io/pub/v/rdf_mapper_annotations.svg)](https://pub.dev/packages/rdf_mapper_annotations)
[![build](https://github.com/kkalass/rdf_mapper_annotations/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_mapper_annotations/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_mapper_annotations/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_mapper_annotations)
[![license](https://img.shields.io/github/license/kkalass/rdf_mapper_annotations.svg)](https://github.com/kkalass/rdf_mapper_annotations/blob/main/LICENSE)

A powerful, declarative annotation system for seamless mapping between Dart objects and RDF graphs.

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_mapper_annotations/)

`rdf_mapper_annotations` provides the annotation system for declaring how to map between Dart objects and RDF data, similar to how an ORM works for databases. These annotations are used by the `rdf_mapper_generator` package to generate the actual mapping code. With this concise annotation system, you can define how your domain model maps to RDF without writing boilerplate serialization code.

### Key Features

- **Declarative annotations** for clean, maintainable code
- **Type-safe mapping** between Dart classes and RDF resources
- **Support for code generation** (via rdf_mapper_generator)
- **Flexible IRI generation strategies** for resource identification
- **Comprehensive collection support** for lists, sets, and maps
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

1. Add dependencies to your project:

```bash
# Add runtime dependencies
dart pub add rdf_core rdf_mapper rdf_mapper_annotations
dart pub add rdf_vocabularies  # Optional but recommended for standard vocabularies

# Add development dependencies
dart pub add build_runner --dev
dart pub add rdf_mapper_generator --dev
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

3. Generate mappers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

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
  IriStrategy('{baseUri}/persons/{id}')  // {baseUri} is not directly from a class field
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
  IriStrategy('{baseUri}/organizations/{id}')  // Same placeholder across models
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
  datatype: IriTerm.prevalidated('http://example.org/temperature'),
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',
)
class Temperature {
  final double celsius;
  
  Temperature(this.celsius);
  
  String formatCelsius() => '$celsius°C';
  
  static Temperature parse(String value) {
    return Temperature(double.parse(value.replaceAll('°C', '')));
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
  - `@RdfIri` for reference values with specialized formats

- **Model relationships correctly** - Use IRI mapping for references to other resources rather than string literals

## Learn More

For detailed examples, including complex mappings, vector clocks, IRI strategies, and more, see the [examples](https://github.com/kkalass/rdf_mapper_annotations/tree/main/example) directory.

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_mapper_annotations/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
