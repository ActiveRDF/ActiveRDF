package org.activerdf.wrapper.sesame2;

import java.io.File;
import java.io.StringWriter;

import java.io.IOException;

import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.Repository;
import org.openrdf.repository.sail.SailRepository;
import org.openrdf.sail.Sail;
import org.openrdf.sail.memory.MemoryStore;
import org.openrdf.sail.nativerdf.NativeStore;
import org.openrdf.sail.inferencer.fc.ForwardChainingRDFSInferencer;
import org.openrdf.rio.RDFFormat;
import org.openrdf.model.Resource;
import org.openrdf.rio.ntriples.NTriplesWriter;
import org.openrdf.model.URI;
import org.openrdf.model.Literal;
import org.openrdf.query.QueryLanguage;
import org.openrdf.query.TupleQuery;
import org.openrdf.query.TupleQueryResult;

import org.openrdf.repository.RepositoryException;
import org.openrdf.rio.RDFParseException;
import org.openrdf.rio.RDFHandlerException;
import org.openrdf.query.MalformedQueryException;
import org.openrdf.query.QueryEvaluationException;

/**
 * construct a wrapper for a sesame2 repository. 
 * many sesame2 classes use an initialize method, which clashes with the 
 * ruby naming requirement, to name the constructor initialize. 
 * Because of this it is currently not possible to construct such objects from jruby
 * but instead embarrsing wrappers, such as this have to be used. 
 * 
 * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
 */
public class WrapperForSesame2 {

    protected RepositoryConnection sesameConnection;
    protected Repository sesameRepository;

    /**
     * the constructor. it does nothing. 
     * all the real work has to be done by the callConstrcutor methods, because JRuby currently
     * cant manage custom class loaders _and_ constructors with arguments.. yes, its sad. 
     */
    public WrapperForSesame2() {
    // do nothing
    }

    /**
     * construct a wrapper for a sesame2 repository. 
     * many sesame2 classes use an initialize method, which clashes with the 
     * ruby naming requirement, to name the constructor initialize. 
     * Because of this it is currently not possible to construct such objects from jruby
     * but instead embarrsing wrappers, such as this have to be used. 
     * 
     * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
     * 
     * @param file - if given a sesame2 the file will be used for persistance and loaded if already existing
     * @param inferencing - if given, the sesame2 repository will use rdfs inferencing
     * 
     * @return the sesame connection of the sesame repository associated with this wrapper.
     */
    public RepositoryConnection callConstructor(File file, boolean inferencing) {
        Sail sailStack;
        if (file == null) {
            sailStack = new MemoryStore();
        } else {
            sailStack = new NativeStore(file);
        }

        if (inferencing) {
            sailStack = new ForwardChainingRDFSInferencer(sailStack);
        }


        try {
            sesameRepository = new SailRepository(sailStack);
            sesameRepository.initialize();
            sesameConnection = sesameRepository.getConnection();
            sesameConnection.setAutoCommit(true);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return sesameConnection;
    }

    /**
     * construct a wrapper for a sesame2 repository. 
     * many sesame2 classes use an initialize method, which clashes with the 
     * ruby naming requirement, to name the constructor initialize. 
     * Because of this it is currently not possible to construct such objects from jruby
     * but instead embarrsing wrappers, such as this have to be used. 
     * 
     * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
     *
     * Uses in memory repository and rdfs inferencing. 
     *
     * @return the sesame connection of the sesame repository associated with this wrapper.
     */
    public RepositoryConnection callConstructor() {
        return callConstructor(null, true);
    }

    /**
     * construct a wrapper for a sesame2 repository. 
     * many sesame2 classes use an initialize method, which clashes with the 
     * ruby naming requirement, to name the constructor initialize. 
     * Because of this it is currently not possible to construct such objects from jruby
     * but instead embarrsing wrappers, such as this have to be used. 
     * 
     * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
     *
     * Uses in memory repository.
     * 
     * @param inferencing - if given, the sesame2 repository will use rdfs inferencing
     * 
     * @return the sesame connection of the sesame repository associated with this wrapper.
     */
    public RepositoryConnection callConstructor(boolean inferencing) {
        return callConstructor(null, inferencing);
    }

    /**
     * construct a wrapper for a sesame2 repository. 
     * many sesame2 classes use an initialize method, which clashes with the 
     * ruby naming requirement, to name the constructor initialize. 
     * Because of this it is currently not possible to construct such objects from jruby
     * but instead embarrsing wrappers, such as this have to be used. 
     * 
     * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
     * 
     * Uses rdfs inferencing. 
     * 
     * @param file if given a sesame2 NativeStore using this directory will be constructed
     * 
     * @return the sesame connection of the sesame repository associated with this wrapper.
     */
    public RepositoryConnection callConstructor(File file) {
        return callConstructor(file, true);
    }

    /**
     * @return the sesame connection of the sesame repository associated with this wrapper.
     */
    public RepositoryConnection getSesameConnection() {
        return sesameConnection;
    }

    /**
     * load data from file
     * 
     * @param file A file containing RDF data
     * @param baseUri The base URI to resolve any relative URIs that are 
     * in the data against. This defaults to the value of file.toURI() 
     * if the value is set to null
     * @param dataFormat The serialization format of the data.
     * @param context The contexts to add the data to. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * specified, the data is added to any context specified in the actual 
     * data file, or if the data contains no context, it is added without 
     * context. If one or more contexts are specified the data is added to 
     * these contexts, ignoring any context information in the data itself.
     * @return boolean
     */
    public boolean load(String file, String baseUri, RDFFormat dataFormat, Resource context) {
        try {
            File dataFile = new File(file);
            if (context == null) {
                sesameConnection.add(dataFile, baseUri, dataFormat);
            } else {
                sesameConnection.add(dataFile, baseUri, dataFormat, context);
            }

            return true;
        } catch (IOException e) {
            throw new RuntimeException(e);
        } catch (RDFParseException e) {
            throw new RuntimeException(e);
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Exports all explicit statements in the specified contexts to the 
     * supplied RDFHandler
     * 
     * @param context The context(s) to get the data from. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * supplied the method operates on the entire repository.
     * 
     * @return string
     */
    public String dump(Resource context) {
        StringWriter stringWriter = new StringWriter();
        NTriplesWriter sesameWriter = new NTriplesWriter(stringWriter);
        try {
            if (context == null) {
                sesameConnection.export(sesameWriter);
            } else {
                sesameConnection.export(sesameWriter, context);
            }
            return stringWriter.toString();
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        } catch (RDFHandlerException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Returns the number of (explicit) statements that are in the specified 
     * contexts in this repository.
     * 
     * @param context The context(s) to get the data from. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * supplied the method operates on the entire repository.
     *
     * @return long
     */
    public long size(Resource context) {
        try {
            return sesameConnection.size(context);
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Removes all statements from a specific contexts in the repository.
     * 
     * @param context The context(s) to remove the data from. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * supplied the method operates on the entire repository. 
     * 
     * @return boolean
     */
    public boolean clear(Resource context) {
        try {
            if (context == null)
                sesameConnection.clear();
            else
                sesameConnection.clear(context);
            return true;
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Adds a statement with the specified subject, predicate and object to 
     * this repository, optionally to one or more named contexts.
     * 
     * @param subject The statement's subject.
     * @param predicate The statement's predicate.
     * @param object The statement's object.
     * @param context The contexts to add the data to. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * specified, the data is added to any context specified in the actual 
     * data file, or if the data contains no context, it is added without 
     * context. If one or more contexts are specified the data is added to 
     * these contexts, ignoring any context information in the data itself.
     * 
     * @return boolean
     */
    public boolean add(Resource subject, URI predicate, URI object, Resource context) {
        try {
            if (context == null) {
                sesameConnection.add(subject, predicate, object);
            } else {
                sesameConnection.add(subject, predicate, object, context);
            }
            return true;
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Adds a statement with the specified subject, predicate and object to 
     * this repository, optionally to one or more named contexts.
     * 
     * @param subject The statement's subject.
     * @param predicate The statement's predicate.
     * @param object The statement's object.
     * @param context The contexts to add the data to. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * specified, the data is added to any context specified in the actual 
     * data file, or if the data contains no context, it is added without 
     * context. If one or more contexts are specified the data is added to 
     * these contexts, ignoring any context information in the data itself.
     * 
     * @return boolean
     */
    public boolean add(Resource subject, URI predicate, Literal object, Resource context) {
        try {
            if (context == null) {
                sesameConnection.add(subject, predicate, object);
            } else {
                sesameConnection.add(subject, predicate, object, context);
            }
            return true;
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Removes the statement(s) with the specified subject, predicate and 
     * object from the repository, optionally restricted to the specified 
     * contexts.
     * 
     * @param subject The statement's subject, or null for a wildcard.
     * @param predicate The statement's predicate, or null for a wildcard.
     * @param object The statement's object, or null for a wildcard.
     * @param context The context(s) to remove the data from. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * supplied the method operates on the entire repository.
     * 
     * @return boolean
     */
    public boolean remove(Resource subject, URI predicate, URI object, Resource context) {
        try {
            if (context == null) {
                sesameConnection.remove(subject, predicate, object);
            } else {
                sesameConnection.remove(subject, predicate, object, context);
            }
            return true;
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Removes the statement(s) with the specified subject, predicate and 
     * object from the repository, optionally restricted to the specified 
     * contexts.
     * 
     * @param subject The statement's subject, or null for a wildcard.
     * @param predicate The statement's predicate, or null for a wildcard.
     * @param object The statement's object, or null for a wildcard.
     * @param context The context(s) to remove the data from. Note that this 
     * parameter is a vararg and as such is optional. If no contexts are 
     * supplied the method operates on the entire repository.
     * 
     * @return boolean
     */
    public boolean remove(Resource subject, URI predicate, Literal object, Resource context) {
        try {
            if (context == null) {
                sesameConnection.remove(subject, predicate, object);
            } else {
                sesameConnection.remove(subject, predicate, object, context);
            }
            return true;
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Execute a query
     * 
     * @param queryLanguage The query language in which the query is formulated.
     * The value can be SERQL, SERQO or SPARQL.
     * @param query The query string.
     * 
     * @return TupleQueryResult A representation of a variable-binding query 
     * result as a sequence of BindingSet objects. Each query result consists 
     * of zero or more solutions, each of which represents a single query 
     * solution as a set of bindings. Note: take care to always close a 
     * TupleQueryResult after use to free any resources it keeps hold of.
     */
    public TupleQueryResult query(QueryLanguage queryLanguage, String query) {
        TupleQueryResult result;
        try {
            TupleQuery tupleQuery = sesameConnection.prepareTupleQuery(queryLanguage, query);
            result = tupleQuery.evaluate();
        } catch (RepositoryException e) {
            throw new RuntimeException(e);
        } catch (MalformedQueryException e) {
            throw new RuntimeException(e);
        } catch (QueryEvaluationException e) {
            throw new RuntimeException(e);
        }

        return result;
    }
}
