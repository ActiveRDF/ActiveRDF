package org.activerdf.wrapper.sesame2;

import java.io.File;

// the new stuff

import org.openrdf.sail.Sail;
import org.openrdf.sail.NotifyingSail;
import org.openrdf.repository.Repository;
import org.openrdf.repository.sail.SailRepository;
import org.openrdf.sail.memory.MemoryStore;
import org.openrdf.sail.nativerdf.NativeStore;
import org.openrdf.sail.rdbms.RdbmsStore;
import org.openrdf.repository.http.HTTPRepository;
import org.openrdf.sail.inferencer.fc.ForwardChainingRDFSInferencer;
import org.openrdf.sail.inferencer.fc.DirectTypeHierarchyInferencer;
import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.RepositoryException;
import org.openrdf.model.Resource;
import org.openrdf.rio.RDFFormat;


/**
	* construct a wrapper for a sesame2 repository.
	* many sesame2 classes use an initialize method, which clashes with the
	* ruby naming requirement, to name the constructor initialize.
	* Because of this it is currently not possible to construct such objects from jruby
	* but instead emberasing wrappers, such as this have to be used.
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

	/* 
	 * Initialize the Wrapper with a NativeStore as a backend.
	 * @param File dir Data file that the native store will use.
	 * @param String indexes If not null, the store will use the given indexes to speed up queries
	 * @param boolean inferencing If true (and not null), it will activate rdfs inferencing
	 */
	public RepositoryConnection initWithNative(File dir, String indexes, boolean inferencing) {
		Sail sailStack;
		
		if(indexes == null) {
			sailStack = new NativeStore(dir);
		} else {
			sailStack = new NativeStore(dir, indexes);
		}
		
		return initFromSail(sailStack, inferencing);
	}

	/*
	 * Initialize the Wrapper with a MemoryStore as a backend
	 * @param boolean inferencing If true (and not null), it will activate rdfs inferencing
	 */
	public RepositoryConnection initWithMemory(boolean inferencing) {
		return initFromSail(new MemoryStore(), inferencing);
	}
	
	/*
	 * Initialize the Wrapper with a RDBMS as a backend
	 * @param driver JDBC driver to use
	 * @param url JDBC connect URL
	 * @param user Username for the database, or null
	 * @param password Password for the database user, or null
	 */
	public RepositoryConnection initWithRDBMS(String driver, String url, String user, String password, boolean inferencing) {
		Sail sailStack;
		
		if(user == null) {
			sailStack = new RdbmsStore(driver, url);
		} else {
			sailStack = new RdbmsStore(driver, url, user, password);
		}
		
		return initFromSail(sailStack, inferencing);
	}
	
	/*
	 * Initialize th Wrapper with a connection to a remote HTTP repository
	 */
	public RepositoryConnection initWithHttp(String url, String user, String password) throws RepositoryException {
		HTTPRepository httpRepository = new HTTPRepository(url);
		if(user != null) {
			httpRepository.setUsernameAndPassword(user, password);
		}
		httpRepository.initialize();
		sesameRepository = httpRepository;
		sesameConnection = sesameRepository.getConnection();
		return sesameConnection;
	}

	/**
		* @return the sesame connection of the sesame repository associated with this wrapper.
		*/
	public RepositoryConnection getSesameConnection() {
		return sesameConnection;
	}

	/**
		* Load data from file. This is a thin wrapper on the
		* add method of the connection, creating only the File object for
		* it to work on. And yes, we throw everything and let the Ruby
		* side deal with it.
		*/
	public boolean load(String file, String baseUri, RDFFormat dataFormat, Resource... contexts) throws Exception {
		sesameConnection.add(new File(file), baseUri, dataFormat, contexts);
		return true;
	}
	
	
	protected RepositoryConnection initFromSail(Sail sailStack, boolean inferencing) {
		if (inferencing) {
			if(sailStack instanceof NotifyingSail) {
				sailStack = new ForwardChainingRDFSInferencer((NotifyingSail) sailStack);
				sailStack = new DirectTypeHierarchyInferencer((NotifyingSail) sailStack);
			} else {
				throw new RuntimeException("Cannot create inferencing: Incompatible Sail type.");
			}
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

}