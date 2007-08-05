package org.activerdf.wrapper.sesame2;

import java.io.File;

// the new stuff

import org.openrdf.sail.Sail;
import org.openrdf.repository.Repository;
import org.openrdf.repository.sail.SailRepository;
import org.openrdf.sail.memory.MemoryStore;
import org.openrdf.sail.nativerdf.NativeStore;
import org.openrdf.sail.nativerdf.NativeStoreRDFSInferencer;
import org.openrdf.sail.memory.MemoryStoreRDFSInferencer;
import org.openrdf.repository.RepositoryConnection;


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
	
	
	/**
	 * construct a wrapper for a sesame2 repository. 
	 * many sesame2 classes use an initialize method, which clashes with the 
	 * ruby naming requirement, to name the constructor initialize. 
	 * Because of this it is currently not possible to construct such objects from jruby
	 * but instead embarrsing wrappers, such as this have to be used. 
	 * 
	 * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
	 * 
	 * @param File dir - if given a sesame2 the file will be used for persistance and loaded if already existing
	 * 
	 * @param String indexes - used by the Sesame Native Store for query speed, example "spoc,posc,cosp"
	 * 
	 * @param boolean inferencing - if given, the sesame2 repository will use rdfs inferencing
	 */
	public RepositoryConnection callConstructor(File dir, String indexes, boolean inferencing) {
		Sail sailStack;
		
		if (dir == null) {
			sailStack = new MemoryStore();
		} else {
			if (indexes == null) {
				sailStack = new MemoryStore(dir);
			} else {
				sailStack = new NativeStore(dir, indexes);
			}
				
		}
		
		if (inferencing) {
			if (sailStack instanceof MemoryStore) 
				sailStack = new MemoryStoreRDFSInferencer(sailStack);
			else
				sailStack = new NativeStoreRDFSInferencer(sailStack);
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
	 */
	public RepositoryConnection callConstructor() {
		return callConstructor(null, null, true);
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
	 * @param boolean inferencing - if given, the sesame2 repository will use rdfs inferencing
	 */
	public RepositoryConnection callConstructor(boolean inferencing) {
		return callConstructor(null, null, inferencing);
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
	 * @param File dataDir - if given a sesame2 NativeStore using this directory will be constructed
	 */
	public RepositoryConnection callConstructor(File dataDir) {
		return callConstructor(dataDir, null, true);
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
	 * 
	 * @param File dataDir - if given a sesame2 NativeStore using this directory will be constructed
	 * 
	 * @param Boolean inferencing - specify if inferncing should be enabled
	 */
	public RepositoryConnection callConstructor(File dataDir, Boolean inferencing) {
		return callConstructor(dataDir, null, inferencing);
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
	 * @param File dataDir - if given a sesame2 NativeStore using this directory will be constructed
	 * 
	 * @param String indexes - used by the Sesame Native Store for query speed, example "spoc,posc,cosp"
	 */
	public RepositoryConnection callConstructor(File dataDir, String indexes) {
		return callConstructor(dataDir, indexes, true);
	}
	
	
	/**
	 * @return the sesame connection of the sesame repository associated with this wrapper.
	 */
	public RepositoryConnection getSesameConnection() {
		return sesameConnection;
	}
	
}
