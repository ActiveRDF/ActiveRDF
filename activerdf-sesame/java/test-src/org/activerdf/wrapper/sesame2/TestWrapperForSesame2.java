package org.activerdf.wrapper.sesame2;

import java.io.File;
import java.io.IOException;

import org.activerdf.wrapper.sesame2.WrapperForSesame2;
import org.openrdf.repository.RepositoryConnection;
import org.openrdf.repository.RepositoryException;

import junit.framework.TestCase;

public class TestWrapperForSesame2 extends TestCase {
	
	protected WrapperForSesame2 myWrapper; 
	
	protected void setUp() {
		myWrapper = new WrapperForSesame2();
	}

    protected void tearDown() throws RepositoryException {
    	myWrapper.getSesameConnection().close();
    }

	
	public void testJustGetTheWrapper() {
		myWrapper.callConstructor(null, null, false);
	}

	public void testMemoryStorePersistence() throws IOException {
		File location = new File(new File (".").getCanonicalFile().toString() + "/../test/sesame-persistence-test1");
		myWrapper.callConstructor(location, null, false);
	}

	public void NativeStorePersistence() throws IOException {
		File location = new File(new File (".").getCanonicalFile().toString() + "/../test/sesame-persistence-test2");
		myWrapper.callConstructor(location, "spoc,pocs", false);
	}

	
}

