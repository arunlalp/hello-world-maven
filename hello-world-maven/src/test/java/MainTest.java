package com.example;

import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Unit tests for the Main class
 */
public class MainTest {

    @Test
    public void testMainClassExists() {
        // Test that the Main class can be loaded
        try {
            Class<?> mainClass = Class.forName("com.example.Main");
            assertNotNull("Main class should exist", mainClass);
        } catch (ClassNotFoundException e) {
            fail("Main class should be loadable: " + e.getMessage());
        }
    }

    @Test
    public void testMainMethodExists() {
        // Test that the main method exists and has the correct signature
        try {
            Class<?> mainClass = Main.class;
            var mainMethod = mainClass.getMethod("main", String[].class);
            
            assertNotNull("Main method should exist", mainMethod);
            assertTrue("Main method should be public", 
                      java.lang.reflect.Modifier.isPublic(mainMethod.getModifiers()));
            assertTrue("Main method should be static", 
                      java.lang.reflect.Modifier.isStatic(mainMethod.getModifiers()));
            assertEquals("Main method should return void", 
                        void.class, mainMethod.getReturnType());
        } catch (NoSuchMethodException e) {
            fail("Main method should exist: " + e.getMessage());
        }
    }

    @Test
    public void testMainPackage() {
        // Test that the Main class is in the correct package
        Package pkg = Main.class.getPackage();
        assertNotNull("Package should not be null", pkg);
        assertEquals("Package should be com.example", "com.example", pkg.getName());
    }

    @Test 
    public void testClassStructure() {
        // Test that the Main class has the expected structure
        Class<?> mainClass = Main.class;
        assertTrue("Main class should be public", 
                  java.lang.reflect.Modifier.isPublic(mainClass.getModifiers()));
        assertFalse("Main class should not be abstract", 
                   java.lang.reflect.Modifier.isAbstract(mainClass.getModifiers()));
        assertFalse("Main class should not be interface", 
                   mainClass.isInterface());
    }

    @Test
    public void testDefaultConstructor() {
        // Test that Main class can be instantiated
        try {
            Main main = new Main();
            assertNotNull("Main instance should be created", main);
        } catch (Exception e) {
            fail("Main should have accessible default constructor: " + e.getMessage());
        }
    }
}