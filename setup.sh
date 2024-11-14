#!/bin/bash

echo "=== Node.js Update and Character Creator Setup ==="

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script is designed for Linux. Please modify for your OS."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install or update nvm
install_nvm() {
    echo "Installing/Updating nvm..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
        # Install nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
        # Load nvm manually after install
        export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        # Verify nvm is loaded
        if ! command_exists nvm; then
            echo "Please run these commands manually:"
            echo "export NVM_DIR=\"\$HOME/.nvm\""
            echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\""
            echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\""
            echo "Then run: ./setup.sh again"
            exit 1
        fi
    fi
}

# Update Node.js
update_node() {
    echo "Updating Node.js..."
    # Load nvm if it exists but isn't loaded
    if [ -s "$HOME/.nvm/nvm.sh" ] && ! command_exists nvm; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    
    # Verify nvm is available
    if ! command_exists nvm; then
        echo "Error: nvm is not available. Please ensure it's installed and loaded."
        exit 1
    fi
    
    nvm install node # Install latest version
    nvm alias default node # Set as default
    nvm use node # Use latest version
    
    # Clean up old versions
    echo "Cleaning up old Node.js versions..."
    current_version=$(nvm current)
    for version in $(nvm ls | grep "v" | grep -v "$current_version"); do
        nvm uninstall "$(echo $version | tr -d '[:space:]')" 2>/dev/null
    done
}

# Create character creator script
create_character_script() {
    echo "Creating character creator script..."
    cat > character-creator.cjs << 'EOF'
const readline = require('readline');
const fs = require('fs').promises;
const { v4: uuidv4 } = require('uuid');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

const modelProviders = [
  'openai',
  'anthropic',
  'local',
  'together',
  'groq'
];

const imageGenModels = [
  'dall-e-3',
  'stable-diffusion',
  'midjourney'
];

async function createCharacter() {
  console.log('\n=== Eliza Character Creation Wizard ===\n');
  
  try {
    // Basic Information
    const name = await question('Enter character name: ');
    const useUUID = (await question('Include UUID? (y/n): ')).toLowerCase() === 'y';
    const id = useUUID ? uuidv4() : undefined;
    
    // System and Model Settings
    console.log('\nAvailable model providers:', modelProviders.join(', '));
    const modelProvider = await question('Enter model provider: ');
    if (!modelProviders.includes(modelProvider)) {
      throw new Error('Invalid model provider');
    }
    
    const useImageGen = (await question('Include image generation? (y/n): ')).toLowerCase() === 'y';
    let imageGenModel;
    if (useImageGen) {
      console.log('Available image generation models:', imageGenModels.join(', '));
      imageGenModel = await question('Enter image generation model: ');
      if (!imageGenModels.includes(imageGenModel)) {
        throw new Error('Invalid image generation model');
      }
    }
    
    const system = await question('Enter system prompt (optional, press Enter to skip): ');
    const modelOverride = await question('Enter model override (optional, press Enter to skip): ');
    
    // Character Background
    console.log('\n=== Character Background ===');
    const bio = await question('Enter character bio: ');
    
    const lore = [];
    console.log('\nEnter lore items (enter empty line to finish):');
    while (true) {
      const item = await question('Lore item: ');
      if (!item) break;
      lore.push(item);
    }
    
    // Message Examples
    const messageExamples = [];
    console.log('\nEnter message example pairs (enter empty line in prompt to finish):');
    while (true) {
      const prompt = await question('Example prompt: ');
      if (!prompt) break;
      const response = await question('Example response: ');
      messageExamples.push([prompt, response]);
    }
    
    // Post Examples
    const postExamples = [];
    console.log('\nEnter post examples (enter empty line to finish):');
    while (true) {
      const post = await question('Post example: ');
      if (!post) break;
      postExamples.push(post);
    }
    
    // Additional Information
    console.log('\n=== Additional Information ===');
    const people = (await question('Enter relevant people (comma-separated): ')).split(',').map(p => p.trim()).filter(Boolean);
    const topics = (await question('Enter relevant topics (comma-separated): ')).split(',').map(t => t.trim()).filter(Boolean);
    const adjectives = (await question('Enter character adjectives (comma-separated): ')).split(',').map(a => a.trim()).filter(Boolean);
    const knowledge = (await question('Enter knowledge areas (comma-separated, optional): ')).split(',').map(k => k.trim()).filter(Boolean);
    
    // Clients
    const clients = (await question('Enter supported clients (comma-separated): ')).split(',').map(c => c.trim()).filter(Boolean);
    
    // Settings
    const includeSettings = (await question('Include additional settings? (y/n): ')).toLowerCase() === 'y';
    let settings;
    if (includeSettings) {
      settings = {};
      const includeSecrets = (await question('Include secrets? (y/n): ')).toLowerCase() === 'y';
      if (includeSecrets) {
        settings.secrets = {};
        console.log('\nEnter secrets (enter empty key to finish):');
        while (true) {
          const key = await question('Secret key: ');
          if (!key) break;
          const value = await question('Secret value: ');
          settings.secrets[key] = value;
        }
      }
      
      const includeVoice = (await question('Include voice settings? (y/n): ')).toLowerCase() === 'y';
      if (includeVoice) {
        settings.voice = {};
        settings.voice.model = await question('Voice model: ');
        settings.voice.url = await question('Voice URL: ');
      }
      
      const modelSetting = await question('Enter model setting (optional): ');
      if (modelSetting) settings.model = modelSetting;
      
      const embeddingModel = await question('Enter embedding model (optional): ');
      if (embeddingModel) settings.embeddingModel = embeddingModel;
    }
    
    // Style
    console.log('\n=== Style Settings ===');
    const styleAll = (await question('Enter general style traits (comma-separated): ')).split(',').map(s => s.trim()).filter(Boolean);
    const styleChat = (await question('Enter chat-specific style traits (comma-separated): ')).split(',').map(s => s.trim()).filter(Boolean);
    const stylePost = (await question('Enter post-specific style traits (comma-separated): ')).split(',').map(s => s.trim()).filter(Boolean);
    
    // Create character object
    const character = {
      ...(id && { id }),
      name,
      ...(system && { system }),
      modelProvider,
      ...(imageGenModel && { imageGenModel }),
      ...(modelOverride && { modelOverride }),
      bio,
      lore,
      messageExamples,
      postExamples,
      people,
      topics,
      adjectives,
      ...(knowledge.length && { knowledge }),
      clients,
      ...(settings && { settings }),
      style: {
        all: styleAll,
        chat: styleChat,
        post: stylePost
      }
    };
    
    // Save to file
    const filename = `${name.toLowerCase().replace(/\s+/g, '_')}.character.json`;
    await fs.writeFile(filename, JSON.stringify(character, null, 2));
    console.log(`\nCharacter file saved as: ${filename}`);
    
  } catch (error) {
    console.error('Error creating character:', error.message);
  } finally {
    rl.close();
  }
}

createCharacter();
EOF
}

# Main script execution
echo "Starting setup..."

# Check if nvm is loaded
if ! command_exists nvm; then
    install_nvm
fi

# Verify nvm is now available
if ! command_exists nvm; then
    echo "Please close this terminal, open a new one, and run the script again."
    exit 1
fi

# Update Node.js
update_node

# Create package.json if it doesn't exist
if [ ! -f package.json ]; then
    echo "Initializing npm project..."
    echo '{"name": "character-creator","version": "1.0.0","type": "commonjs"}' > package.json
fi

# Install required packages
echo "Installing required packages..."
npm install uuid

# Create character creator script
create_character_script

# Make script executable
chmod +x character-creator.cjs

echo "Setup complete! Running character creator..."
echo "----------------------------------------"

# Run the character creator
node character-creator.cjs

echo "----------------------------------------"
echo "Done! Your character file has been created."
