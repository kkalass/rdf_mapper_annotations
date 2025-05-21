import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';

class MockItemClass {}

void main() {
  group('RdfCollectionOf', () {
    test('constructor sets item class', () {
      final annotation = RdfCollectionOf(MockItemClass);

      expect(annotation.itemClass, equals(MockItemClass));
    });
  });

  group('RdfCollectionKey', () {
    test('constructor creates instance', () {
      final annotation = RdfCollectionKey();

      expect(annotation, isA<RdfAnnotation>());
      expect(annotation, isA<RdfCollectionKey>());
    });

    test('constructor is const', () {
      expect(identical(const RdfCollectionKey(), const RdfCollectionKey()),
          isTrue);
    });
  });

  group('RdfCollectionValue', () {
    test('constructor creates instance', () {
      final annotation = RdfCollectionValue();

      expect(annotation, isA<RdfAnnotation>());
      expect(annotation, isA<RdfCollectionValue>());
    });

    test('constructor is const', () {
      expect(identical(const RdfCollectionValue(), const RdfCollectionValue()),
          isTrue);
    });
  });

  group('RdfCollectionType', () {
    test('enum values are correct', () {
      expect(RdfCollectionType.values.length, equals(2));
      expect(RdfCollectionType.auto, isA<RdfCollectionType>());
      expect(RdfCollectionType.none, isA<RdfCollectionType>());
    });
  });
}
