import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/property/collection.dart';

const rdfList = CollectionMapping.mapper(RdfListMapper);
const rdfSeq = CollectionMapping.mapper(RdfSeqMapper);
const rdfBag = CollectionMapping.mapper(RdfBagMapper);
const rdfAlt = CollectionMapping.mapper(RdfAltMapper);
const unorderedItems = CollectionMapping.mapper(UnorderedItemsMapper);
const unorderedItemsList = CollectionMapping.mapper(UnorderedItemsListMapper);
const unorderedItemsSet = CollectionMapping.mapper(UnorderedItemsSetMapper);
