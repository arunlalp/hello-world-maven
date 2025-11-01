package com.example;

import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Unit tests for the App class to ensure code coverage
 */
public class AppTest {

    @Test
    public void testAppClassExists() {
        // Test that the App class can be loaded
        try {
            Class<?> appClass = Class.forName("com.example.App");
            assertNotNull("App class should exist", appClass);
        } catch (ClassNotFoundException e) {
            fail("App class should be loadable: " + e.getMessage());
        }
    }

    @Test
    public void testMainMethodExists() {
        // Test that the main method exists and has the correct signature
        try {
            Class<?> appClass = App.class;
            var mainMethod = appClass.getMethod("main", String[].class);
            
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
    public void testAppPackage() {
        // Test that the App class is in the correct package
        Package pkg = App.class.getPackage();
        assertNotNull("Package should not be null", pkg);
        assertEquals("Package should be com.example", "com.example", pkg.getName());
    }

    @Test 
    public void testClassModifiers() {
        // Test that the App class has the expected modifiers
        Class<?> appClass = App.class;
        assertTrue("App class should be public", 
                  java.lang.reflect.Modifier.isPublic(appClass.getModifiers()));
        assertFalse("App class should not be abstract", 
                   java.lang.reflect.Modifier.isAbstract(appClass.getModifiers()));
        assertFalse("App class should not be interface", 
                   appClass.isInterface());
    }

    @Test
    public void testDefaultConstructor() {
        // Test that App class can be instantiated (has default constructor)
        try {
            App app = new App();
            assertNotNull("App instance should be created", app);
        } catch (Exception e) {
            fail("App should have accessible default constructor: " + e.getMessage());
        }
    }
}