
require 'java'



MemoryStore = org.openrdf.sail.memory.MemoryStore

maybeASail = MemoryStore.new

include_class 'org.openrdf.sail.memory.MemoryStore'




#---
 require "java"
 MemoryStore = org.openrdf.sail.memory.MemoryStore
 JClass = java.lang.Class
 JArray = java.lang.reflect.Array
 
 
 # 1.)
 mstore = JClass.forName("org.openrdf.sail.memory.MemoryStore").newInstance
 
 # 2.) 
 rdfsStoreArgsClasses = JArray.newInstance(MemoryStore.class)
 rdfsStoreArgsClasses
 rdfsStoreArgsClasses = [ MemoryStore ]
 rdfsStoreArgsArguments = [mstore]
 rdfsStoreConstructor = JClass.forName("org.openrdf.sail.inferencer.MemoryStoreRDFSInferencer").getConstructor(rdfsStoreArgsClasses)
 rdfsstore = rdfsStoreConstructor.newInstance(rdfsStoreArgsArguments)