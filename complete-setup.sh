#!/bin/bash

echo "🚀 Starting Character Setup Tool installation..."

# Create project directory and navigate into it
mkdir -p character-setup-tool
cd character-setup-tool

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOL'
{
  "name": "character-setup-tool",
  "version": "1.0.0",
  "description": "Interactive CLI tool for creating Eliza character configurations",
  "type": "module",
  "scripts": {
    "start": "cross-env NODE_OPTIONS=\"--loader ts-node/esm\" node src/index.ts"
  },
  "dependencies": {
    "chalk": "^5.3.0",
    "commander": "^11.1.0",
    "inquirer": "^9.2.12",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "@types/inquirer": "^9.0.7",
    "@types/node": "^20.10.5",
    "@types/uuid": "^9.0.7",
    "cross-env": "^7.0.3",
    "ts-node": "^10.9.2",
    "typescript": "^5.3.3"
  }
}
EOL

# Create tsconfig.json
echo "📝 Creating tsconfig.json..."
cat > tsconfig.json << 'EOL'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "ts-node": {
    "esm": true,
    "experimentalSpecifierResolution": "node"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
EOL

# Create src directory
echo "📁 Creating source directory..."
mkdir -p src

# Create index.ts
echo "📄 Creating index.ts..."
cat > src/index.ts << 'EOL'
#!/usr/bin/env node

import { program } from 'commander';
import inquirer from 'inquirer';
import { v4 as uuidv4 } from 'uuid';
import chalk from 'chalk';
import { promises as fs } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface CharacterConfig {
    id: string;
    name: string;
    modelProvider: string;
    imageGenModel?: string;
    bio: string[];
    lore: string[];
    messageExamples: string[][];
    postExamples: string[];
    people: string[];
    topics: string[];
    adjectives: string[];
    knowledge?: string[];
    clients: string[];
    settings?: {
        voice?: {
            model?: string;
            url?: string;
        };
        model?: string;
        embeddingModel?: string;
    };
    style: {
        all: string[];
        chat: string[];
        post: string[];
    };
}

const modelProviders = ['openai', 'anthropic', 'llama', 'grok'] as const;
const imageGenModels = ['dalle3', 'dalle2', 'stable-diffusion'] as const;
const clientTypes = ['discord', 'twitter', 'telegram'] as const;

async function promptForBasicInfo(): Promise<Partial<CharacterConfig>> {
    const answers = await inquirer.prompt([
        {
            type: 'input',
            name: 'name',
            message: 'What is your character\'s name?',
            validate: (input) => input.length >= 2 || 'Name must be at least 2 characters long'
        },
        {
            type: 'list',
            name: 'modelProvider',
            message: 'Select the primary model provider:',
            choices: modelProviders
        },
        {
            type: 'list',
            name: 'imageGenModel',
            message: 'Select the image generation model:',
            choices: [...imageGenModels, 'none'],
            default: 'none'
        }
    ]);

    return {
        id: uuidv4(),
        ...answers,
        imageGenModel: answers.imageGenModel === 'none' ? undefined : answers.imageGenModel
    };
}

async function promptForBioAndLore(): Promise<Partial<CharacterConfig>> {
    console.log(chalk.blue('\nLet\'s define your character\'s background...'));
    
    const answers = await inquirer.prompt([
        {
            type: 'editor',
            name: 'bio',
            message: 'Enter your character\'s bio (one paragraph per line):',
            validate: (input) => input.length > 0 || 'Bio cannot be empty'
        },
        {
            type: 'editor',
            name: 'lore',
            message: 'Enter your character\'s lore (one item per line):',
            validate: (input) => input.length > 0 || 'Lore cannot be empty'
        }
    ]);

    return {
        bio: answers.bio.split('\n').filter(line => line.trim()),
        lore: answers.lore.split('\n').filter(line => line.trim())
    };
}

async function promptForExamples(): Promise<Partial<CharacterConfig>> {
    console.log(chalk.blue('\nNow, let\'s add some example interactions...'));

    const messageExamples = [];
    let addMore = true;
    
    while (addMore) {
        const example = await inquirer.prompt([
            {
                type: 'input',
                name: 'user',
                message: 'Enter a user message:',
                validate: (input) => input.length > 0 || 'Message cannot be empty'
            },
            {
                type: 'input',
                name: 'response',
                message: 'Enter the character\'s response:',
                validate: (input) => input.length > 0 || 'Response cannot be empty'
            }
        ]);

        messageExamples.push([`User: ${example.user}`, `Response: ${example.response}`]);

        const { continue: shouldContinue } = await inquirer.prompt({
            type: 'confirm',
            name: 'continue',
            message: 'Add another example interaction?',
            default: false
        });

        addMore = shouldContinue;
    }

    const { postExamples } = await inquirer.prompt({
        type: 'editor',
        name: 'postExamples',
        message: 'Enter example social media posts (one per line):'
    });

    return {
        messageExamples,
        postExamples: postExamples.split('\n').filter(line => line.trim())
    };
}

async function promptForAttributes(): Promise<Partial<CharacterConfig>> {
    console.log(chalk.blue('\nLet\'s define your character\'s attributes...'));

    const answers = await inquirer.prompt([
        {
            type: 'editor',
            name: 'people',
            message: 'Enter types of people your character interacts with (one per line):'
        },
        {
            type: 'editor',
            name: 'topics',
            message: 'Enter topics your character is knowledgeable about (one per line):'
        },
        {
            type: 'editor',
            name: 'adjectives',
            message: 'Enter adjectives that describe your character (one per line):'
        },
        {
            type: 'editor',
            name: 'knowledge',
            message: 'Enter specific areas of knowledge (one per line):'
        }
    ]);

    return {
        people: answers.people.split('\n').filter(line => line.trim()),
        topics: answers.topics.split('\n').filter(line => line.trim()),
        adjectives: answers.adjectives.split('\n').filter(line => line.trim()),
        knowledge: answers.knowledge.split('\n').filter(line => line.trim())
    };
}

async function promptForClients(): Promise<Partial<CharacterConfig>> {
    const { clients } = await inquirer.prompt({
        type: 'checkbox',
        name: 'clients',
        message: 'Select the platforms this character will operate on:',
        choices: clientTypes
    });

    return { clients };
}

async function promptForSettings(): Promise<Partial<CharacterConfig>> {
    console.log(chalk.blue('\nLet\'s configure your character\'s settings...'));

    const answers = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'useVoice',
            message: 'Would you like to enable voice capabilities?',
            default: false
        },
        {
            type: 'input',
            name: 'model',
            message: 'Enter the default language model to use:',
            default: 'gpt-4'
        },
        {
            type: 'input',
            name: 'embeddingModel',
            message: 'Enter the embedding model to use:',
            default: 'text-embedding-3-small'
        }
    ]);

    const settings: NonNullable<CharacterConfig['settings']> = {
        model: answers.model,
        embeddingModel: answers.embeddingModel
    };

    if (answers.useVoice) {
        const voiceSettings = await inquirer.prompt([
            {
                type: 'input',
                name: 'model',
                message: 'Enter the voice model:',
                default: 'eleven_multilingual_v2'
            },
            {
                type: 'input',
                name: 'url',
                message: 'Enter the voice API URL:',
                default: 'https://api.elevenlabs.io/v1/text-to-speech'
            }
        ]);

        settings.voice = voiceSettings;
    }

    return { settings };
}

async function promptForStyle(): Promise<Partial<CharacterConfig>> {
    console.log(chalk.blue('\nFinally, let\'s define your character\'s communication style...'));

    const answers = await inquirer.prompt([
        {
            type: 'editor',
            name: 'all',
            message: 'Enter general style attributes (one per line):'
        },
        {
            type: 'editor',
            name: 'chat',
            message: 'Enter chat-specific style attributes (one per line):'
        },
        {
            type: 'editor',
            name: 'post',
            message: 'Enter post-specific style attributes (one per line):'
        }
    ]);

    return {
        style: {
            all: answers.all.split('\n').filter(line => line.trim()),
            chat: answers.chat.split('\n').filter(line => line.trim()),
            post: answers.post.split('\n').filter(line => line.trim())
        }
    };
}

async function main() {
    console.log(chalk.green('Welcome to the Character Setup Wizard! 🧙‍♂️\n'));
    console.log(chalk.yellow('This tool will guide you through creating a character configuration file.\n'));

    try {
        const basicInfo = await promptForBasicInfo();
        const bioAndLore = await promptForBioAndLore();
        const examples = await promptForExamples();
        const attributes = await promptForAttributes();
        const clients = await promptForClients();
        const settings = await promptForSettings();
        const style = await promptForStyle();

        const characterConfig: CharacterConfig = {
            ...basicInfo,
            ...bioAndLore,
            ...examples,
            ...attributes,
            ...clients,
            ...settings,
            ...style
        } as CharacterConfig;

        const outputPath = join(process.cwd(), `${characterConfig.name.toLowerCase()}.json`);
        await fs.writeFile(
            outputPath,
            JSON.stringify(characterConfig, null, 2),
            'utf-8'
        );

        console.log(chalk.green('\nCharacter configuration has been saved! 🎉'));
        console.log(chalk.blue(`File location: ${outputPath}`));
        
        console.log(chalk.yellow('\nTo use this character, run:'));
        console.log(chalk.white(`node --loader ts-node/esm src/index.ts --characters="${outputPath}"\n`));

    } catch (error) {
        console.error(chalk.red('An error occurred:'), error);
        process.exit(1);
    }
}

program
    .name('create-eliza-character')
    .description('Interactive CLI tool for creating Eliza character configurations')
    .version('1.0.0')
    .action(main)
    .parse(process.argv);
EOL

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Make the script executable
echo "🔑 Making scripts executable..."
chmod +x src/index.ts

echo "✨ Setup complete! You can now run the tool with: npm start"
echo "📝 The interactive character creation wizard will guide you through the process."
