# RDF Mapper Annotations for Dart

[![pub package](https://img.shields.io/pub/v/rdf_mapper_annotations.svg)](https://pub.dev/packages/rdf_mapper_annotations)
[![build](https://github.com/kkalass/rdf_mapper_annotations/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_mapper_annotations/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_mapper_annotations/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_mapper_annotations)
[![license](https://img.shields.io/github/license/kkalass/rdf_mapper_annotations.svg)](https://github.com/kkalass/rdf_mapper_annotations/blob/main/LICENSE)

Dart annotations for declarative RDF graph mapping and code generation.

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_mapper_annotations/)

`rdf_mapper_annotations` provides an elegant solution for transforming between Dart object models and RDF graphs, similar to an ORM for databases. This enables developers to work with semantic data in an object-oriented manner without manually managing the complexity of transforming between dart objects and RDF triples.

## Quick Start

1. Add dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  rdf_core: ^latest
  rdf_mapper: ^latest
  rdf_mapper_annotations: ^latest
  rdf_vocabularies: ^latest # Optional but recommended

dev_dependencies:
  build_runner: ^latest
  rdf_mapper_generator: ^latest
```

2. Define your data model with RDF annotations:

```dart
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

@RdfGlobalResource(SchemaBook.classIri, RdfIri('http://example.org/book/{id}'))
class Book {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  @RdfProperty(SchemaBook.hasPart)
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.author,
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
dart run build_runner build
```

4. Use the generated mappers:

```dart
void main() {
  // Initialize the generated mapper
  final mapper = initRdfMapper();
  
  // Create a book with chapters
  final book = Book(
    id: '123',
    title: 'RDF Mapping with Dart',
    author: 'Klas Kalaß',
    chapters: [
      Chapter('Getting Started', 1),
      Chapter('Advanced Mapping', 2),
    ],
  );
  
  // Convert to RDF graph
  final graph = mapper.serialize(book);
  print(graph.toString());
  
  // Parse back to Dart object
  final parsedBook = mapper.deserialize<Book>(graph);
  print(parsedBook.title); // 'RDF Mapping with Dart'
}
```

For more detailed examples, see the [examples](https://github.com/kkalass/rdf_mapper_annotations/tree/main/example) directory.

---

## Part of a whole family of projects

If you are looking for more rdf-related functionality, have a look at our companion projects:

* basic graph classes as well as turtle/jsonld/n-triple encoding and decoding: [rdf_core](https://github.com/kkalass/rdf_core) 
* encode and decode rdf/xml format: [rdf_xml](https://github.com/kkalass/rdf_xml) 
* easy-to-use constants for many well-known vocabularies: [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies)
* generate your own easy-to-use constants for other vocabularies with a build_runner: [rdf_vocabulary_to_dart](https://github.com/kkalass/rdf_vocabulary_to_dart)

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_mapper_annotations/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
