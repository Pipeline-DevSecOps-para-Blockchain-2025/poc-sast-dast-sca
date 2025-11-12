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

# Array of available tools with their Docker contexts
declare -A tools_config
tools_config["slither"]="Docker/slither"
tools_config["mythril"]="Docker/mythril"

# Build tool-specific images
for tool in "${!tools_config[@]}"; do
    tool_dir="${tools_config[$tool]}"
    
    if [ -d "$tool_dir" ] && [ -f "$tool_dir/Dockerfile" ]; then
        print_status "Building $tool Docker image..."
        
        if docker build -t "security-tools-poc:$tool" "$tool_dir/"; then
            print_success "$tool image built successfully"
        else
            print_error "Failed to build $tool image"
            continue
        fi
    else
        print_warning "Skipping $tool - Dockerfile not found in $tool_dir"
    fi
done

# List built images
print_status "Listing built images..."
docker images | grep security-tools-poc || print_warning "No security-tools-poc images found"

# Test images
print_status "Testing Docker images..."

test_image() {
    local tool=$1
    local test_command=$2
    
    print_status "Testing $tool image..."
    
    if docker run --rm "security-tools-poc:$tool" $test_command &> /dev/null; then
        print_success "$tool image test passed"
        return 0
    else
        print_warning "$tool image test failed"
        return 1
    fi
}

# Test available tool images
for tool in "${!tools_config[@]}"; do
    if docker image inspect "security-tools-poc:$tool" &> /dev/null; then
        case $tool in
            "slither")
                test_image "$tool" "--version"
                ;;
            "mythril")
                test_image "$tool" "version"
                ;;
        esac
    fi
done

print_success "Docker image build process completed!"
echo ""
echo "Available images:"
for tool in "${!tools_config[@]}"; do
    if docker image inspect "security-tools-poc:$tool" &> /dev/null; then
        echo "  - security-tools-poc:$tool"
    fi
done
echo ""
echo "Usage examples:"
echo "  # Run Slither analysis:"
echo "  docker run --rm -v \$(pwd)/contracts:/contracts security-tools-poc:slither /contracts"
echo ""
echo "  # Run Mythril analysis:"
echo "  docker run --rm -v \$(pwd)/contracts:/contracts security-tools-poc:mythril analyze /contracts/MyContract.sol"
echo ""
echo "  # Interactive shell:"
echo "  docker run -it --rm -v \$(pwd):/workspace security-tools-poc:slither bash"