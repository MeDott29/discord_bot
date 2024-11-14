#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to setup NVM and Node.js
setup_node() {
    # Check if NVM is installed
    if [ ! -d "$HOME/.nvm" ]; then
        print_message "$YELLOW" "Installing NVM (Node Version Manager)..."
        # Install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

        # Setup NVM environment variables
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

        # Add NVM to shell profile if not already present
        if ! grep -q "NVM_DIR" ~/.bashrc; then
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        fi

        if [ $? -ne 0 ]; then
            print_message "$RED" "Failed to install NVM"
            return 1
        fi
    fi

    # Ensure NVM is loaded
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install Node.js 22 LTS if not already installed
    if ! command_exists node || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 22 ]; then
        print_message "$YELLOW" "Installing Node.js 22..."
        nvm install 22
        nvm use 22
        nvm alias default 22

        if [ $? -ne 0 ]; then
            print_message "$RED" "Failed to install Node.js"
            return 1
        fi
    fi

    # Verify Node.js installation
    if ! command_exists node; then
        print_message "$RED" "Node.js installation failed"
        return 1
    fi

    print_message "$GREEN" "Node.js $(node -v) has been installed and configured"
    return 0
}

# Function to check Node.js version
check_node_version() {
    if ! command_exists node; then
        print_message "$YELLOW" "Node.js not found, installing..."
        setup_node
        return $?
    fi

    local node_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 22 ]; then
        print_message "$YELLOW" "Node.js version must be 22 or higher. Current version: $(node -v)"
        print_message "$YELLOW" "Installing correct Node.js version..."
        setup_node
        return $?
    fi
    
    print_message "$GREEN" "Node.js version check passed: $(node -v)"
    return 0
}

# Function to check if pnpm is installed
check_pnpm() {
    if ! command_exists pnpm; then
        print_message "$RED" "pnpm is not installed!"
        print_message "$YELLOW" "Installing pnpm..."
        npm install -g pnpm
        if [ $? -ne 0 ]; then
            print_message "$RED" "Failed to install pnpm"
            return 1
        fi
    fi
    print_message "$GREEN" "pnpm is installed: $(pnpm --version)"
    return 0
}

# Main installation function
main_install() {
    print_message "$YELLOW" "Starting Eliza installation process..."

    # Setup Node.js environment
    print_message "$YELLOW" "Checking Node.js environment..."
    check_node_version
    if [ $? -ne 0 ]; then
        print_message "$RED" "Failed to setup Node.js environment"
        exit 1
    fi

    check_pnpm
    if [ $? -ne 0 ]; then
        print_message "$RED" "Failed to setup pnpm"
        exit 1
    fi

    # Clean existing installation
    print_message "$YELLOW" "Cleaning existing installation..."
    rm -rf node_modules core/node_modules pnpm-lock.yaml core/pnpm-lock.yaml
    if [ $? -ne 0 ]; then
        print_message "$RED" "Failed to clean existing installation"
        exit 1
    fi

    # Install ONNX Runtime 1.20.0 explicitly first
    print_message "$YELLOW" "Installing ONNX Runtime 1.20.0..."
    pnpm add onnxruntime-node@1.20.0 --save-exact -w
    if [ $? -ne 0 ]; then
        print_message "$RED" "Failed to install ONNX Runtime 1.20.0"
        exit 1
    fi

    # Add resolution for ONNX Runtime in package.json
    print_message "$YELLOW" "Adding ONNX Runtime resolution to package.json..."
    if [ -f package.json ]; then
        # Check if resolutions field exists
        if ! grep -q '"resolutions"' package.json; then
            # Add resolutions field before the last closing brace
            sed -i '/"dependencies":/i \  "resolutions": {\n    "onnxruntime-node": "1.20.0"\n  },' package.json
        fi
    fi

    # Install dependencies with workspace flag
    print_message "$YELLOW" "Installing dependencies..."
    pnpm install --include=optional sharp -w
    if [ $? -ne 0 ]; then
        print_message "$RED" "Installation failed"
        exit 1
    fi

    # Ensure consistent ONNX Runtime version across workspace
    print_message "$YELLOW" "Ensuring consistent ONNX Runtime version..."
    find . -name "package.json" -exec sed -i 's/"onnxruntime-node": "[^"]*"/"onnxruntime-node": "1.20.0"/g' {} +

    # Force reinstall to apply resolutions
    print_message "$YELLOW" "Applying dependency resolutions..."
    pnpm install --force -w

    # Check if .env file exists
    # if [ ! -f .env ]; then
    #     print_message "$YELLOW" "Creating .env file from example..."
    #     cp .env.example .env
    #     print_message "$YELLOW" "Please edit .env file with your configuration"
    # fi

    print_message "$GREEN" "Installation completed successfully!"
    print_message "$YELLOW" "Next steps:"
    print_message "$NC" "1. Edit your .env file with appropriate values"
    print_message "$NC" "2. Run 'source ~/.bashrc' to reload your shell environment"
    print_message "$NC" "3. Run 'pnpm start' to start Eliza"
    print_message "$YELLOW" "NOTE: If Node.js is not found after closing the terminal, run:"
    print_message "$NC" "    source ~/.bashrc"
}

# Run the installation
main_install