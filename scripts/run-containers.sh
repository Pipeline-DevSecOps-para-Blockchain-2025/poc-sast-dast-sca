#!/bin/bash

# Run Security Tools PoC Containers
# This script provides easy commands to run security analysis tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    echo "Usage: $0 <tool> <command> [options]"
    echo ""
    echo "Available tools:"
    echo "  slither   - Static analysis for Solidity"
    echo "  mythril   - Security analysis for EVM bytecode"
    echo ""
    echo "Commands:"
    echo "  analyze <contract_path>  - Run analysis on contract"
    echo "  shell                    - Start interactive shell"
    echo "  help                     - Show tool help"
    echo ""
    echo "Examples:"
    echo "  $0 slither analyze contracts/vulnerable/MyContract.sol"
    echo "  $0 mythril analyze contracts/vulnerable/MyContract.sol"
    echo "  $0 slither shell"
    echo "  $0 mythril help"
    echo ""
    echo "Options:"
    echo "  --output-dir <dir>       - Output directory for results (default: poc-results)"
    echo "  --workspace <dir>        - Workspace directory (default: poc-workspace)"
}

# Parse arguments
TOOL=""
COMMAND=""
CONTRACT_PATH=""
OUTPUT_DIR="poc-results"
WORKSPACE_DIR="poc-workspace"

while [[ $# -gt 0 ]]; do
    case $1 in
        slither|mythril)
            TOOL="$1"
            shift
            ;;
        analyze|shell|help)
            COMMAND="$1"
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            if [[ -z "$CONTRACT_PATH" && "$COMMAND" == "analyze" ]]; then
                CONTRACT_PATH="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$TOOL" || -z "$COMMAND" ]]; then
    print_error "Missing required arguments"
    show_usage
    exit 1
fi

# Change to project root
cd "$(dirname "$0")/.."

# Create directories
mkdir -p "$OUTPUT_DIR" "$WORKSPACE_DIR"

# Check if image exists
if ! docker image inspect "security-tools-poc:$TOOL" &> /dev/null; then
    print_error "Docker image security-tools-poc:$TOOL not found"
    print_status "Run './scripts/build-docker-images.sh' first"
    exit 1
fi

# Execute command
case "$COMMAND" in
    analyze)
        if [[ -z "$CONTRACT_PATH" ]]; then
            print_error "Contract path required for analyze command"
            exit 1
        fi
        
        if [[ ! -f "$CONTRACT_PATH" ]]; then
            print_error "Contract file not found: $CONTRACT_PATH"
            exit 1
        fi
        
        print_status "Running $TOOL analysis on $CONTRACT_PATH"
        
        case "$TOOL" in
            slither)
                docker run --rm \
                    -v "$(pwd):/workspace" \
                    -v "$(pwd)/$OUTPUT_DIR:/results" \
                    --workdir /workspace \
                    "security-tools-poc:slither" \
                    "$CONTRACT_PATH" \
                    --json "/results/slither-$(basename "$CONTRACT_PATH" .sol)-$(date +%Y%m%d-%H%M%S).json"
                ;;
            mythril)
                docker run --rm \
                    -v "$(pwd):/workspace" \
                    -v "$(pwd)/$OUTPUT_DIR:/results" \
                    --workdir /workspace \
                    "security-tools-poc:mythril" \
                    analyze "$CONTRACT_PATH" \
                    --output-dir "/results" \
                    --output-format json
                ;;
        esac
        ;;
        
    shell)
        print_status "Starting interactive shell for $TOOL"
        docker run -it --rm \
            -v "$(pwd):/workspace" \
            -v "$(pwd)/$OUTPUT_DIR:/results" \
            -v "$(pwd)/$WORKSPACE_DIR:/poc-workspace" \
            --workdir /workspace \
            --entrypoint /bin/sh \
            "security-tools-poc:$TOOL"
        ;;
        
    help)
        print_status "Showing help for $TOOL"
        docker run --rm "security-tools-poc:$TOOL" --help
        ;;
        
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

print_success "Command completed successfully"