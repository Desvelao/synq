#!/usr/bin/env bash

# Development script for project

set -e

OUTPUT_BIN="synq"
INTPUT_GO="./main.go"

# Build the project
echo "Building the project..."
go build -o "$OUTPUT_BIN" "$INTPUT_GO"

# Format code and README
echo "Formatting source files..."
./scripts/format.sh

# Run tests
echo "Running tests..."
go test ./...

# Start the application
echo "Starting the application..."
./"$OUTPUT_BIN" --help

# Additional commands can be added here for further development tasks.