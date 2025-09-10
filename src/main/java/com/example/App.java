package com.example;

// The necessary imports for default metrics and manual exposition
import io.prometheus.client.CollectorRegistry;
import io.prometheus.client.exporter.common.TextFormat;
import io.prometheus.client.hotspot.DefaultExports;
import java.io.StringWriter;
import java.io.IOException;

// We need to import the static methods from the Spark class
import static spark.Spark.*;

/**
 * A simple web application exposing default Prometheus metrics.
 */
public class App {

    public static void main(String[] args) {

        // 1. Initialize a registry for the metrics.
        CollectorRegistry collectorRegistry = new CollectorRegistry();
        // Initialize default JVM metrics and register them with our registry.
        DefaultExports.initialize();


        // --- DEFINE YOUR ROUTES HERE ---

        // 2. Route for exposing Prometheus metrics manually.
        get("/metrics", (request, response) -> {
            // Set the content type for Prometheus
            response.type(TextFormat.CONTENT_TYPE_004);

            StringWriter writer = new StringWriter();
            try {
                // Write the metrics from the registry to the writer
                TextFormat.write004(writer, CollectorRegistry.defaultRegistry.metricFamilySamples());
            } catch (IOException e) {
                // This is unlikely to happen with a StringWriter
                e.printStackTrace();
            }
            return writer.toString();
        });

        // Route 1: Responds to GET requests on the root path "/"
        get("/", (request, response) -> {
            return "Welcome to the Home Page!";
        });

        // Route 2: Responds to GET requests on the "/hello" path
        get("/hello", (request, response) -> {
            return "Hello, CI/CD World!";
        });

        // Route 3: A dynamic route that accepts a parameter in the path
        get("/greet/:name", (request, response) -> {
            String name = request.params(":name");
            return "Hello, " + name + "!";
        });

        System.out.println("Server is running! Access it at http://localhost:4567");
        System.out.println("Default metrics available at http://localhost:4567/metrics");
    }
}

