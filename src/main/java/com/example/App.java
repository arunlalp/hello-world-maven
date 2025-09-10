package com.example;

// We need to import the static methods from the Spark class
import static spark.Spark.*;

/**
 * A simple web application demonstrating path-based routing.
 */
public class App {
    public static void main(String[] args) {

        // Spark automatically starts a server on http://localhost:4567
        // You don't need to configure anything else for a simple app.

        // --- DEFINE YOUR ROUTES HERE ---

        // Route 1: Responds to GET requests on the root path "/"
        get("/", (request, response) -> {
            return "Welcome to the Home Page!";
        });

        // Route 2: Responds to GET requests on the "/hello" path
        get("/hello", (request, response) -> {
            return "Hello, CI/CD World!";
        });

        // Route 3: A dynamic route that accepts a parameter in the path
        // For example: /greet/John or /greet/Jane
        get("/greet/:name", (request, response) -> {
            // Retrieve the "name" parameter from the request URL
            String name = request.params(":name");
            return "Hello, " + name + "!";
        });

        System.out.println("Server is running! Access it at http://localhost:4567");
    }
}

