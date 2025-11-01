#!/bin/bash

# Quick Docker build, test, and cleanup script
echo "🚀 Building Docker image..."
docker build -t hello-world-maven:latest .

echo "🏃 Starting container..."
docker run -d -p 4567:4567 --name hello-world-quick-test hello-world-maven:latest

echo "⏳ Waiting for application to start..."
sleep 15

echo "🧪 Testing endpoints..."
echo "Root endpoint response:"
curl -s http://localhost:4567/

echo -e "\n\nHello endpoint response:"
curl -s http://localhost:4567/hello

echo -e "\n\nGreet endpoint response:"
curl -s http://localhost:4567/greet/Docker

echo -e "\n\nMetrics available at: http://localhost:4567/metrics"

echo -e "\n\n📊 Container status:"
docker ps --filter name=hello-world-quick-test

echo -e "\n🧹 To stop and cleanup:"
echo "docker stop hello-world-quick-test && docker rm hello-world-quick-test"