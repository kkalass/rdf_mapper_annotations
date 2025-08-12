import 'package:test/test.dart';
import 'package:rdf_mapper_annotations/src/property/contextual_mapping.dart';

void main() {
  group('ContextualMapping', () {
    test('named constructor creates instance with correct name', () {
      final mapping = ContextualMapping.named('example');
      expect(mapping.name, equals('example'));
    });

    test('equality comparison works correctly', () {
      final mapping1 = ContextualMapping.named('test');
      final mapping2 = ContextualMapping.named('test');
      final mapping3 = ContextualMapping.named('other');

      expect(mapping1, equals(mapping2));
      expect(mapping1, isNot(equals(mapping3)));
    });

    test('hashCode is based on name', () {
      final mapping1 = ContextualMapping.named('test');
      final mapping2 = ContextualMapping.named('test');

      expect(mapping1.hashCode, equals(mapping2.hashCode));
    });

    test('toString returns correct format', () {
      final mapping = ContextualMapping.named('primaryTopic');
      expect(mapping.toString(),
          equals('ContextualMapping.named("primaryTopic")'));
    });

    test('named factory method works correctly', () {
      final mapping = ContextualMapping.named('test');
      expect(mapping.name, equals('test'));
    });

    test('named constructor creates different instances for different names',
        () {
      final mapping1 = ContextualMapping.named('first');
      final mapping2 = ContextualMapping.named('second');

      expect(mapping1.name, equals('first'));
      expect(mapping2.name, equals('second'));
      expect(mapping1, isNot(equals(mapping2)));
    });
  });
}
