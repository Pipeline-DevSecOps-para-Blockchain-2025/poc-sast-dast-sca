#!/bin/bash

# Build Docker Images for Security Tools PoC
# This script builds all Docker images required for the PoC system

set -e

echo "Building Security Tools PoC Docker Images"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_success "Docker is available and running"

# Change to project root directory
cd "$(dirname "$0")/.."

# Create necessary directories
print_status "Creating workspace directories..."
mkdir -p poc-workspace poc-temp poc-results

# Create Docker network
print_status "Creating Docker network..."
if ! docker network inspect security-tools-poc-network &> /dev/null; then
    docker network create security-tools-poc-network
    print_success "Docker network created: security-tools-poc-network"
else
    print_warning "Docker network already exists: security-tools-poc-network"
fi

# Build base image
print_status "Building base Docker image..."
if docker build -f docker/Dockerfile.base -t security-tools-poc:base docker/; then
    print_success "Base image built successfully"
else
    print_error "Failed to build base image"
    exit 1
fi

# Array of tools to build
tools=("slither" "mythril" "echidna" "foundry")

# Build tool-specific images
for tool in "${tools[@]}"; do
    print_status "Building $tool Docker image..."
    
    if docker build -f docker/Dockerfile.$tool -t security-tools-poc:$tool docker/; then
        print_success "$tool image built successfully"
    else
        print_error "Failed to build $tool image"
        # Continue with other tools instead of exiting
        continue
    fi
done

# List built images
print_status "Listing built images..."
docker images | grep security-tools-poc

# Test images
print_status "Testing Docker images..."

test_image() {
    local tool=$1
    local test_command=$2
    
    print_status "Testing $tool image..."
    
    if docker run --rm security-tools-poc:$tool $test_command &> /dev/null; then
        print_success "$tool image test passed"
        return 0
    else
        print_warning "$tool image test failed"
        return 1
    fi
}

# Test each tool image
test_image "slither" "slither --version"
test_image "mythril" "myth version"
test_image "echidna" "echidna-test --version"
test_image "foundry" "forge --version"

print_success "Docker image build process completed!"
echo ""
echo "Next steps:"
echo "  1. Run 'npm install' to install Node.js dependencies"
echo "  2. Run 'npm run build' to compile TypeScript"
echo "  3. Use the PoC system with Docker containers"
echo ""
echo "To start a tool container:"
echo "  docker run -it --rm -v \$(pwd)/poc-workspace:/poc-workspace security-tools-poc:slither"
echo ""
echo "To use docker-compose:"
echo "  cd docker && docker compose --profile slither up"