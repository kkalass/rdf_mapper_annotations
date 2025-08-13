# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.1] - 2025-08-13

### Added
- **Contextual Property Mapping**: New `contextual` parameter for `@RdfProperty` annotation enables properties to access parent object, parent subject, and full context during RDF operations
- **ContextualMapping class**: Configuration class for contextual property mapping with `ContextualMapping.namedProvider()` factory method
- Enables complex scenarios like computing dependent object IRIs based on parent properties or creating nested resources that reference their container
- **Global Unmapped Triples**: New `globalUnmapped` parameter for `@RdfUnmappedTriples` annotation enables collecting unmapped triples from entire graph instead of just current subject. Designed for top-level document classes like Solid WebID/Profile Documents.
- **Document-level lossless mapping example**: Added `example/document_example.dart` demonstrating global unmapped triples preservation for complete document round-trip fidelity

### Changed
- **ContextualMapping API refinement**: Unified mapping class hierarchy by extending `BaseMapping<SerializationProvider>` for consistent constructor patterns and type safety
- **Enhanced `BaseMapping` generics**: Removed `Mapper` constraint from generic parameter to support broader range of mapping configurations including `SerializationProvider`
- **Improved documentation**: Enhanced `@RdfUnmappedTriples` documentation with performance considerations, usage guidelines, and clear distinction between subject-scoped and global unmapped triples
- **Updated dependencies**: Upgraded `rdf_vocabularies_core` and `rdf_vocabularies_schema` to version `^0.4.4` and switched to local path dependency for `rdf_mapper` for development

### Enhanced
- **Comprehensive lossless mapping guide**: Expanded README documentation with detailed comparison of different unmapped triples strategies and when to use each approach
- **Better example organization**: Enhanced documentation structure with clear sections for subject-scoped vs global unmapped triples with practical use cases

## [0.10.0] - 2025-07-25

### Changed

- **Breaking Change**: Updated `rdf_vocabularies` dependency to use the new multipackage structure:
  - Replaced `rdf_vocabularies: ^0.3.0` with `rdf_vocabularies_core: ^0.4.1` and `rdf_vocabularies_schema: ^0.4.1`
  - Updated all import statements throughout the codebase to use the new package structure
  - `import 'package:rdf_vocabularies/rdf.dart'` → `import 'package:rdf_vocabularies_core/rdf.dart'`
  - `import 'package:rdf_vocabularies/xsd.dart'` → `import 'package:rdf_vocabularies_core/xsd.dart'`
  - `import 'package:rdf_vocabularies/schema.dart'` → `import 'package:rdf_vocabularies_schema/schema.dart'`
  - And similar updates for other vocabulary imports (`foaf`, `vcard`, etc.)

## [0.3.2] - 2025-07-24

### Changed
- **Dependency updates**: Updated to rdf_core ^0.9.11 and rdf_mapper ^0.9.3 for latest bug fixes and improvements
- **Documentation formatting**: Improved consistency in API documentation with proper formatting of generic type references (`List<T>`, `Set<T>`)
- **Code quality**: Enhanced formatting and readability in tool scripts and examples

## [0.3.1] - 2025-07-18

### Added
- **Comprehensive collection mapping documentation**: Added extensive documentation with examples for all collection mapping constants (`rdfList`, `rdfSeq`, `rdfBag`, `rdfAlt`, `unorderedItems`, `unorderedItemsList`, `unorderedItemsSet`)
- **Public collection constants library**: New `collection_constants.dart` library file for convenient access to collection mapping constants
- **Enhanced IRI mapping documentation**: Added detailed documentation for collection item IRI mapping with template placeholder requirements and common usage patterns

### Enhanced
- **Improved API documentation**: Complete documentation overhaul for collection mapping constants with RDF structure examples, use cases, and underlying mapper information
- **Better example quality**: Fixed template placeholder names in examples to match property names correctly
- **Documentation coverage**: Added comprehensive library-level documentation explaining when and how to use each collection mapping strategy

## [0.3.0] - 2025-07-17

### Added
- **New `LiteralContent` class**: Added helper class for building RDF literals with simplified datatype and language handling
- **Enhanced datatype support**: `@RdfLiteral.custom` now accepts optional `datatype` parameter for consistent datatype handling
- **Collection item type specification**: Added `itemType` parameter to `@RdfProperty` for explicit item type control in custom collections
- **Global collection mapping constants**: Added convenient constants (`rdfList`, `rdfSeq`, `rdfBag`, `rdfAlt`, `unorderedItems`, `unorderedItemsList`, `unorderedItemsSet`) for common collection mapping strategies

### Changed
- **BREAKING**: `@RdfLiteral.custom` methods now use `LiteralContent` instead of `LiteralTerm` for parameters and return types
- **BREAKING**: `@RdfProperty.collection` parameter changed from `RdfCollectionType` enum to `CollectionMapping?` for much more flexibility and better API consistency
- **BREAKING**: Removed `RdfCollectionType` enum - collection behavior now specified through `CollectionMapping` class
- **Enhanced collection mapping defaults**: Clarified that collections default to `CollectionMapping.auto()` behavior (multiple triples) unlike other mapping properties which default to registry lookup
- Adjusted to API changes in rdf_mapper (Iterable<Triple>, datatype property in LiteralTermMapper etc.)
- Updated examples and documentation to use new global collection constants

### Removed
- **BREAKING**: `RdfCollectionType` enum - replaced with `CollectionMapping` class for collection mapper specification

## [0.2.4] - 2025-07-10

### Added
- **Lossless mapping support**: Added `@RdfUnmappedTriples` annotation for capturing unmapped RDF triples during deserialization
- **Enhanced examples**: Updated `catch_all.dart` example to demonstrate both `@RdfUnmappedTriples` and `RdfGraph` usage for comprehensive RDF data handling
- **Comprehensive documentation**: Added detailed "Lossless RDF Mapping" section to README with object-level and document-level mapping examples
- **Feature showcase**: Updated project documentation to highlight lossless mapping capabilities

### Enhanced
- **Improved example quality**: Enhanced `catch_all.dart` with realistic Person class and full round-trip usage demonstration
- **Better documentation coverage**: Added usage examples for `encodeObjectLossless`/`decodeObjectLossless` methods for complete document preservation
- **Feature visibility**: Added lossless mapping feature card to project documentation homepage

## [0.2.3] - 2025-07-04

### Changed

- Improved example code quality and readability
- Renamed example file to ensure better discoverability on pub.dev
- Ensured all source files are properly formatted according to Dart conventions

## [0.2.2] - 2025-07-04

### Changed

- Updated README to reflect that the generator package is released and ready for use


## [0.2.1] - 2025-06-25

### Added
- **Comprehensive enum support**: Added `@RdfEnumValue` annotation for customizing individual enum constant serialization values
- **Enhanced `@RdfLiteral` for enums**: Extended `@RdfLiteral` annotation to support direct application to enums with automatic mapper generation
- **Enhanced `@RdfIri` for enums**: Extended `@RdfIri` annotation to support enum mapping with IRI templates and `{value}` placeholder substitution
- **Property-level enum overrides**: Enum properties can now use all existing property-level mapping options (custom mappers, language tags, datatypes)
- **Validation and documentation**: Added comprehensive validation rules, error handling documentation, and best practices for enum mapping
- **Examples and guides**: Added `example/enum_mapping_simple.dart` and `doc/enum_mapping_guide.md` with complete usage examples

### Enhanced
- **Improved documentation**: Updated main library documentation with enum usage examples and integration patterns
- **Extended property mappings**: Enhanced `LiteralMapping` and `IriMapping` classes with enum-specific documentation and examples

## [0.2.0] - 2025-06-20

### Changed
- **BREAKING**: Updated dependency to rdf_mapper ^0.8.0 and adjusted to breaking API changes in the underlying mapper library
- **BREAKING**: Fixed design issues in `@RdfLiteral.custom()` constructor - methods now work with `LiteralTerm` instead of `String` so that they can me used for any LiteralTerm (de-)serialization (including language tags). 
- Updated IRI template semantics to support `{+variable}` syntax for context variables that may contain URI-reserved characters (prevents percent-encoding)
- Improved documentation for IRI template variables and context variable handling

### Fixed
- Corrected parameter order and nullability in `@RdfLiteral.custom()` constructor
- Updated examples to work with the new rdf_mapper 0.8.0 API

## [0.1.0] - 2025-05-23

### Added

- Initial Release - Added all annotations and some examples
- Comprehensive documentation for all annotation classes
- Quick start example in README.md