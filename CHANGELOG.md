# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **New `LiteralContent` class**: Added helper class for building RDF literals with simplified datatype and language handling
- **Enhanced datatype support**: `@RdfLiteral.custom` now accepts optional `datatype` parameter for consistent datatype handling
- **Collection item type specification**: Added `itemType` parameter to `@RdfProperty` for explicit item type control in custom collections

### Changed
- **BREAKING**: `@RdfLiteral.custom` methods now use `LiteralContent` instead of `LiteralTerm` for parameters and return types
- **BREAKING**: `@RdfProperty.collection` parameter changed from `RdfCollectionType` enum to `Type?` for direct mapper type specification
- **BREAKING**: Removed `RdfCollectionType` enum - collection behavior now specified through mapper types
- Adjusted to API changes in rdf_mapper (Iterable<Triple>, datatype property in LiteralTermMapper etc.)
- Updated examples and documentation to reflect new API patterns

### Removed
- **BREAKING**: `RdfCollectionType` enum - replaced with direct Type specification for collection mappers

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