package org.activerdf.wrapper.sesame2;

import java.io.File;

import org.openrdf.repository.Connection;
import org.openrdf.repository.Repository;
import org.openrdf.repository.RepositoryImpl;
import org.openrdf.sail.Sail;
import org.openrdf.sail.inferencer.MemoryStoreRDFSInferencer;
import org.openrdf.sail.memory.MemoryStore;
import org.openrdf.sail.nativerdf.NativeStore;

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
	
	protected Connection sesameConnection;

	protected Repository sesameRepository;
	
	/**
	 * construct a wrapper for a sesame2 repository. 
	 * many sesame2 classes use an initialize method, which clashes with the 
	 * ruby naming requirement, to name the constructor initialize. 
	 * Because of this it is currently not possible to construct such objects from jruby
	 * but instead embarrsing wrappers, such as this have to be used. 
	 * 
	 * check http://jira.codehaus.org/browse/JRUBY-45 to see if bug still exists.
	 * 
	 * @param File file - if given a sesame2 the file will be used for persistance and loaded if already existing
	 * 
	 * @param boolean inferencing - if given, the sesame2 repository will use rdfs inferencing
	 */
	public WrapperForSesame2(File file, boolean inferencing) {
		Sail sailStack;
		if (file == null) {
			sailStack = new MemoryStore();
		} else {
			sailStack = new MemoryStore(file);
		}
		
		if (inferencing) {
			sailStack = new MemoryStoreRDFSInferencer(sailStack);
		}
		
		try {
			sesameRepository = new RepositoryImpl(sailStack);
			sesameRepository.initialize();
			sesameConnection = sesameRepository.getConnection();
			sesameConnection.setAutoCommit(true);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
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
	public WrapperForSesame2() {
		this(null, true);
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
	public WrapperForSesame2(boolean inferencing) {
		this(null, inferencing);
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
	public WrapperForSesame2(File file) {
		this(file, true);
	}

	/**
	 * @return the sesame connection of the sesame repository associated with this wrapper.
	 */
	public Connection getSesameConnection() {
		return sesameConnection;
	}
	
}
