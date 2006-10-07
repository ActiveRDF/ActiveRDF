# scenario's: 
# - construct class model: renaud
# - lookup resource: renaud
# - find resource: renaud
# - read attr. value: eyal
# - write attr. value: eyal
#
#
# Object logic 
#  instance mngr | class mngr | namespace manager
# Caching Graph 
#  lookup & update | complete graph
# Query Engine
# Federation
# Adapter
#  connector | translator | triples
#
# graph model is accessible from everywhere (sidebar)
#
# dependencies:
# Class: Graph, QE
# QE: Graph (construct query), Federation (execute query)
# Federation: Adapter (execute query), Graph (merge results)
# Adapter: Connector (execute query on datasource), Translator (transform triples/graph)
# Translator: Graph, Triple (translate up/down)

# federation manager: 
# 1. ensure single connection to single datasource (REUSE)
# 2. retrieve right datasource for some task, e.g. writable (SELECT)
# 3. distribute query and aggregate results (FEDERATE)


class RedlandAdapter
	writable = true
	down = Graph2SparqlTranslator.new
	up  = RedlandRubyTranslator.new
	connector = RedlandConnector.new

	def query(graph)
		result = connector.query(down(graph))
		return up(results)
	end
end

# managing graph in memory cache
# caching options
# 1. RDF(S)::Core (builtin to ActiveRDF 
# 2. schema caching (classes and properties)
# 3. instance caching (deletion slightly inefficient)

# deletion scenario: QE builds delete
# QE: federation.delete(graph)
# federation: adapter.delete(graph)
# adapter figures out which subgraph will be deleted (same subgraph will be 
# deleted in memory)
class Adapter
	def delete(graph)
		deleted = query(graph)
		delete(graph)
		return deleted
	end
end

class Federation
	def delete(graph)
		pool.writable.delete(graph)
	end
end

class QueryEngine
	def delete(graph)
		deleted = federation.delete(graph)
		graph.remove_graph(subgraph)
	end
end

class Graph
	def add(source, edge, target)
	end

	def remove(source, edge, target)
	end

	def add_graph(datagraph)
	end

	def remove_graph(datagraph)
	end

	def nodes
	end

	def lookup(content)
	end
end

# code below now CHANGED: adapter receives and returns graphs

# in adapter:
def query(qs)
	results = query(qs)
	# an example, actual code would depend on number of result bindings (in this 
	# case, we only consider triples)
	results.each do |s,p,o|
		# an example, actual code would depend on parse-type of s, p, and o
		yield URI.new(s), URI.new(p), Literal.new(o)
	end
end

# in QueryEngine (including translator)
# before this we have code building the query... such as select, condition, 
# keyword
def query
	query_graph = build_graph # builds a query graph from the current query options
	result_graph = Graph.new

	datasource.query(translator.query_string(query_graph)).each do |s,p,o|
		$graph.add(s,p,o)
	end
	return result_graph
end

# in class logic (static API)
def get(property)
	qe.select :o
	qe.condition self, property, :o
	nodes = qe.execute
	nodes.collect do |n|
		# instance manager returns objects, such as Strings or Persons
		InstanceManager.retrieve(n)
	end
end

# in instance manager (part of OMM)
def retrieve(node)
	if cache.contains? node
		cache[node]
	else
		node_type = node.outgoing(RDF::type)
		node_class = retrieve(type)
		cache[node] = node_class.send(:create, node)
	end
end

# in Resource (or Person, virtually)
def create(uri)
	node = graph.lookup(uri)
	OMM.retrieve(node)
end

# OMM manages cache if cache enabled
#
# OMM builds class model (need to work out further)
# def add_namespace(prefix, symbol)
# def add_class(URI, symbol)
# def add_instance(URI, symbol)
