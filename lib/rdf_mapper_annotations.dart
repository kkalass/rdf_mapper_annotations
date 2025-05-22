/// Annotation library for mapping Dart classes to RDF graphs.
///
/// This library provides a set of annotations that can be applied to Dart classes and
/// properties to declare how they should be mapped to and from RDF graphs. Used in
/// conjunction with the `rdf_mapper_generator` package, these annotations enable
/// automatic generation of mapper implementations without writing boilerplate code.
///
/// **Core RDF mapping concepts**:
/// - **Resource**: An entity in the RDF graph, which can be identified by an IRI (global)
///   or represented as a blank node (local)
/// - **Property**: A relation between a resource and a value (another resource or a literal)
/// - **IRI (Internationalized Resource Identifier)**: A unique identifier for a resource
/// - **Blank Node**: An anonymous resource without a global identifier
/// - **Literal**: A simple value like a string, number, or date
///
/// **Integration with rdf_mapper**: You don't need to use annotations for all your classes.
/// You can freely mix and match:
/// - Annotated classes with automatically generated mappers
/// - Custom mapper implementations registered directly with `rdf_mapper`
///
/// This flexibility allows you to use annotations for standard cases while implementing
/// custom mappers for more complex scenarios. Custom mappers can be registered either:
/// - Globally after calling `initRdfMapper`
/// - Locally for specific operations via the `register` parameter in mapper methods
///
/// Example using annotations (recommended for most cases):
/// ```dart
/// import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
/// import 'package:rdf_vocabularies/foaf.dart'; // Contains RDF vocabulary terms
///
/// // Define your class with annotations
/// @RdfGlobalResource(FoafPerson.classIri, IriStrategy('http://example.org/people/{id}'))
/// class Person {
///   @RdfIriPart('id')
///   final String id;
///
///   @RdfProperty(FoafPerson.name)
///   final String name;
///
///   @RdfProperty(FoafPerson.age)
///   final int age;
///
///   Person({required this.id, required this.name, required this.age});
/// }
///
/// // The mapper is automatically generated and registered within initRdfMapper
/// final rdfMapper = initRdfMapper();
/// final personTurtle = rdfMapper.encodeObject(person);
/// final decodedPerson = rdfMapper.decodeObject<Person>(personTurtle);
/// ```
///
/// Example of manually implementing and registering a mapper:
/// ```dart
/// // Manual mapper implementation
/// class PersonMapper implements GlobalResourceMapper<Person> {
///   @override
///   (IriTerm, List<Triple>) toRdfResource(Person instance, SerializationContext context, {RdfSubject? parentSubject}) {
///     return context.resourceBuilder(IriTerm(instance.id))
///       .literal(FoafPerson.name, instance.name)
///       .build();
///   }
///
///   @override
///   Person fromRdfResource(IriTerm subject, DeserializationContext context) {
///     return Person(
///       id: subject.iri,
///       name: context.reader.require<String>(FoafPerson.name),
///     );
///   }
///
///   @override
///   IriTerm get typeIri => FoafPerson.classIri;
/// }
///
/// // Register globally after initRdfMapper:
/// final rdfMapper = initRdfMapper(); // From generated code
/// rdfMapper.registerMapper<Person>(PersonMapper());
///
/// // Or register for a specific operation:
/// final turtle = rdfMapper.encodeObject(
///   person,
///   register: (registry) => registry.registerMapper<Person>(PersonMapper()),
/// );
/// ```
///
/// You can also combine both approaches, using annotations for most classes and
/// manual mappers for special cases:
/// ```dart
/// // For a class with annotations, the mapper is generated automatically
/// @RdfGlobalResource(FoafPerson.classIri, IriStrategy('http://example.org/people/{id}'))
/// class Person {
///   // Properties with annotations...
/// }
///
/// // For a complex class, implement a custom mapper
/// class CustomEventMapper implements GlobalResourceMapper<Event> {
///   // Custom implementation...
/// }
///
/// // Use both in your application
/// final rdfMapper = initRdfMapper();
/// rdfMapper.registerMapper<Event>(CustomEventMapper());
///
/// // Both mappers are now available
/// final person = rdfMapper.decodeObject<Person>(personTurtle);
/// final event = rdfMapper.decodeObject<Event>(eventTurtle);
/// ```
///
/// The primary annotations are organized into two categories:
///
/// **Class-level annotations** define how a class is mapped to RDF nodes:
/// - [RdfGlobalResource]: For entities with unique IRIs (subjects)
/// - [RdfLocalResource]: For nested entities as blank nodes
/// - [RdfIri]: For classes representing IRIs
/// - [RdfLiteral]: For classes representing literal values
///
/// **Property-level annotations** define how properties are mapped:
/// - [RdfProperty]: Main property annotation, links to an RDF predicate
/// - [RdfIriPart]: Marks properties that contribute to IRI construction
/// - [RdfValue]: Identifies the value source for literal serialization
/// - [RdfMapEntry]: Specifies how map entries shall be (de-)serialized
///
/// For usage examples, see the [example](https://github.com/kkalass/rdf_mapper_annotations/tree/main/example) directory.
library;

export 'src/base/base_mapping.dart';
export 'src/base/mapper_ref.dart';
export 'src/base/rdf_annotation.dart';

export 'src/property/collection.dart';
export 'src/property/property.dart';
export 'src/property/provides.dart';

export 'src/resource/global_resource.dart';
export 'src/resource/local_resource.dart';

export 'src/term/iri.dart';
export 'src/term/literal.dart';
