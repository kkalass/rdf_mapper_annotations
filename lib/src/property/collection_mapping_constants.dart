import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/property/collection.dart';

const rdfList = CollectionMapping.withItemMappers(RdfListMapper);
const rdfSeq = CollectionMapping.withItemMappers(RdfSeqMapper);
const rdfBag = CollectionMapping.withItemMappers(RdfBagMapper);
const rdfAlt = CollectionMapping.withItemMappers(RdfAltMapper);
const unorderedItems = CollectionMapping.withItemMappers(UnorderedItemsMapper);
const unorderedItemsList =
    CollectionMapping.withItemMappers(UnorderedItemsListMapper);
const unorderedItemsSet =
    CollectionMapping.withItemMappers(UnorderedItemsSetMapper);
