package org.activerdf.wrapper.sesame2;

import java.io.File;

// the new stuff

import org.openrdf.sail.Sail;
import org.openrdf.sail.NotifyingSail;
import org.openrdf.repository.Repository;
import org.openrdf.repository.sail.SailRepository;
import org.openrdf.sail.memory.MemoryStore;
import org.openrdf.sail.nativerdf.NativeStore;
import org.openrdf.sail.inferencer.fc.ForwardChainingRDFSInferencer;
import org.openrdf.repository.RepositoryConnection;
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
				sailStack = new NativeStore(dir);
			} else {
				sailStack = new NativeStore(dir, indexes);
			}

		}

		if (inferencing) {
			if(sailStack instanceof NotifyingSail) {
				sailStack = new ForwardChainingRDFSInferencer((NotifyingSail) sailStack);
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

}