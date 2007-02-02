package org.activerdf.wrapper.sesame2;

import java.io.File;

import org.activerdf.wrapper.sesame2.WrapperForSesame2;

import junit.framework.TestCase;

public class TestWrapperForSesame2 extends TestCase {
	
	public void testJustGetTheWrapper() {
		WrapperForSesame2 myFajitaOrSomething = new WrapperForSesame2(); 
	}

	public void testNativeStore() {
		File location = new File("/home/metaman/workspaces/deri-workspace/activerdf/activerdf-sesame/test/sesame-persistence.s2");
		//assertTrue(location.isFile());
		WrapperForSesame2 myStore = new WrapperForSesame2(location);
	}
	
}
