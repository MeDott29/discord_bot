#!/bin/bash

echo "=== Part 2: Setting up Character Creator ==="

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install latest Node.js
echo "Installing latest Node.js..."
nvm install node
nvm alias default node
nvm use node

# Initialize npm project if needed
if [ ! -f package.json ]; then
    echo "Initializing npm project..."
    echo '{"name": "character-creator","version": "1.0.0","type": "commonjs"}' > package.json
fi

# Create character creator script
echo "Creating character creator script..."
cat > character-creator.cjs << 'EOFJS'
const readline = require('readline');
const fs = require('fs').promises;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

async function createCharacter() {
  console.log('\n=== Eliza Character Creation Wizard ===\n');
  
  try {
    // Basic Information
    const name = await question('Enter character name: ');
    
    // Clients
    console.log('\nAvailable clients: discord, twitter, telegram');
    const clientsInput = await question('Enter clients (comma-separated): ');
    const clients = clientsInput.split(',').map(c => c.trim()).filter(Boolean);
    
    // Settings
    const settings = {
      secrets: {},
      voice: {
        model: await question('Enter voice model (e.g., en_US-male-medium): ')
      }
    };
    
    // Arrays with empty string initialization
    const bio = [''];
    const lore = [''];
    const knowledge = [''];
    const postExamples = [''];
    const topics = [''];
    const adjectives = [''];
    
    // Style
    const style = {
      all: [''],
      chat: [''],
      post: ['']
    };
    
    // Message Examples
    const messageExamples = [];
    console.log('\nEnter message examples (enter empty line in user input to finish)');
    console.log('For each example, you\'ll enter a user message and a response');
    
    while (true) {
      const userMessage = await question('\nUser message (empty line to finish): ');
      if (!userMessage) break;
      
      const responseMessage = await question('Character response: ');
      
      messageExamples.push([
        {
          user: '{{user1}}',
          content: {
            text: userMessage
          }
        },
        {
          user: name,
          content: {
            text: responseMessage
          }
        }
      ]);
    }
    
    // Create character object
    const character = {
      name,
      clients,
      settings,
      bio,
      lore,
      knowledge,
      messageExamples,
      postExamples,
      topics,
      style,
      adjectives
    };
    
    // Save to file
    const filename = `${name.toLowerCase().replace(/\s+/g, '-')}.character.json`;
    await fs.writeFile(filename, JSON.stringify(character, null, 2));
    console.log(`\nCharacter file saved as: ${filename}`);
    
  } catch (error) {
    console.error('Error creating character:', error.message);
  } finally {
    rl.close();
  }
}

createCharacter();
EOFJS

# Make scripts executable
chmod +x character-creator.cjs

echo "Setup complete! Running character creator..."
echo "----------------------------------------"

# Run the character creator
node character-creator.cjs