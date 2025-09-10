# Hello World CI/CD Project

This is a simple **"Hello, World!"** web application built with Java and the SparkJava framework.  
It's designed as a starting point for learning about Continuous Integration and Continuous Deployment (CI/CD) pipelines.

The application is instrumented with **Prometheus** to expose default JVM metrics.

---

## How to Run

### Prerequisites
- Java 11 or newer  
- Apache Maven  

---

### Building the Application
From the project's root directory, run the following Maven command to build the project:

```bash
mvn clean package
````

This will compile the code and create a runnable `.jar` file in the `target/` directory.

---

### Running the Application

You can run the application in two ways:

#### From the command line:

```bash
java -jar target/hello-world-cicd-1.0-SNAPSHOT.jar
```

#### From IntelliJ IDEA:

1. Open the `App.java` file.
2. Click the green **"play"** icon next to the `main` method.

The server will start on:
[http://localhost:4567](http://localhost:4567)

---

## Available Endpoints

* **GET /** → Displays a welcome message.
* **GET /hello** → Displays a `"Hello, CI/CD World!"` message.
* **GET /greet/\:name** → Displays a personalized greeting (e.g., `/greet/Alice`).
* **GET /metrics** → Exposes application metrics in Prometheus format.

