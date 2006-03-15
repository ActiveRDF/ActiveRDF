#!/bin/sh
STORE='test-store'
rm -rf $STORE*
rdfproc $STORE parse file:test\_set.rdf
