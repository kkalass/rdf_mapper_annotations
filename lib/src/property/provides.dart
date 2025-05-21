import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a property as providing a named value that can be referenced in
/// IRI templates throughout the data model.
///
/// This annotation creates a shared variable that can be used in IRI templates
/// of related resources. This is particularly useful for maintaining referential
/// integrity between related entities without duplicating logic.
///
/// Example:
/// ```dart
/// @RdfGlobalResource(
///   TaskVocab.Task.classIri,
///   IriStrategy('{storageRoot}/tasks/{id}.ttl'),
/// )
/// class Task {
///   @RdfIriPart('id')
///   @RdfProvides("taskId") // Makes 'id' available as '{taskId}' in other templates
///   final String id;
///
///   @RdfProperty(TaskVocab.Task.comments)
///   @RdfCollectionOf(Comment)
///   final List<Comment> comments;
///   // ...
/// }
///
/// @RdfGlobalResource(
///   TaskVocab.Comment.classIri,
///   IriStrategy('{storageRoot}/tasks/{taskId}/comments/{commentId}.ttl'),
/// )
/// class Comment {
///   @RdfIriPart('commentId')
///   final String commentId;
///   // The {taskId} in the IRI comes from the Task.id via @RdfProvides
///   // ...
/// }
/// ```
class RdfProvides extends RdfAnnotation {
  /// The name by which this provided value can be referenced in IRI templates.
  final String? name;
  const RdfProvides(this.name);
}
