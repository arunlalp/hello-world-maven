# Hello World CI/CD Project

This is a simple **"Hello, World!"** web application built with Java and the SparkJava framework.  
It's designed as a starting point for learning about Continuous Integration and Continuous Deployment (CI/CD) pipelines.

The application is instrumented with **Prometheus** to expose default JVM metrics and includes a complete **Helm chart** for Kubernetes deployments.

---

## Deployment Options

This project supports multiple deployment methods:

1. **Local Development** - Run directly with Java/Maven
2. **Docker Container** - Using the provided Dockerfile
3. **Azure App Service** - Using Azure DevOps pipeline
4. **Azure Kubernetes Service (AKS)** - Using Helm chart and CI/CD pipeline

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

---

## Kubernetes Deployment with Helm

This project includes a production-ready Helm chart for Kubernetes deployment.

### Quick Start with AKS

1. **Set up Azure resources:**
   ```bash
   ./setup-azure-resources.sh -g myResourceGroup -a myacr12345 -k myAKSCluster
   ```

2. **Build and push Docker image:**
   ```bash
   cd hello-world-maven
   az acr login --name myacr12345
   docker build -t myacr12345.azurecr.io/hello-world-maven:latest .
   docker push myacr12345.azurecr.io/hello-world-maven:latest
   ```

3. **Deploy with Helm:**
   ```bash
   helm install my-app helm-chart \
     --set image.repository=myacr12345.azurecr.io/hello-world-maven \
     --set image.tag=latest
   ```

4. **Validate deployment:**
   ```bash
   ./validate-deployment.sh
   ```

### Helm Chart Features

- ✅ **Security**: Non-root user, security contexts, RBAC
- ✅ **Monitoring**: Prometheus ServiceMonitor, health checks
- ✅ **Scaling**: Horizontal Pod Autoscaler support
- ✅ **Networking**: Service, Ingress with TLS support
- ✅ **Configuration**: Environment-specific values files
- ✅ **Azure Integration**: ACR image pull secrets, AKS optimized

See [`helm-chart/README.md`](hello-world-maven/helm-chart/README.md) for detailed configuration options.

---

## CI/CD Pipeline

The Azure DevOps pipeline (`azure-pipelines.yml`) provides a complete CI/CD workflow:

1. **Build Stage**: Maven compilation with dependency caching
2. **Image Stage**: Docker build and push to Azure Container Registry
3. **Deploy Stage**: Helm-based deployment to Azure Kubernetes Service

### Pipeline Setup

1. **Review the setup guide**: [`PIPELINE-SETUP.md`](PIPELINE-SETUP.md)
2. **Create Azure resources** using the provided script
3. **Configure service connections** in Azure DevOps
4. **Update pipeline variables** with your specific values
5. **Run the pipeline** to build and deploy

---

