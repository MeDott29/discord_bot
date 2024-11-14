import discord
from discord.ext import commands
import pandas as pd
from datetime import datetime, timedelta
import asyncio
import json
import os
kfrom dotenv import load_dotenv

class MessageDataCollector(commands.Bot):
    def __init__(self):
        # Initialize bot with all intents for full message access
        intents = discord.Intents.all()
        super().__init__(command_prefix='!', intents=intents)
        
        # Initialize data structures
        self.message_cache = []
        
        # Add commands
        self.add_command(commands.Command(self.collect_data, name='collect'))
        self.add_command(commands.Command(self.analyze_channel, name='analyze'))
        self.add_command(commands.Command(self.export_data, name='export'))

    async def on_ready(self):
        """Called when bot successfully connects to Discord"""
        print(f'Bot "{self.user.name}" (ID: {self.user.id}) has connected to Discord!')
        print(f'Bot is in {len(self.guilds)} guilds:')
        for guild in self.guilds:
            print(f'- {guild.name} (ID: {guild.id})')

    def create_message_data(self, message):
        """Helper function to create consistent message data structure"""
        return {
            'timestamp': message.created_at.isoformat(),
            'channel_id': message.channel.id,
            'channel_name': message.channel.name,
            'author_id': message.author.id,
            'author_name': str(message.author),
            'content': message.content,
            'is_bot': message.author.bot,
            'attachments': len(message.attachments),
            'mentions': len(message.mentions),
            'reactions': [str(reaction.emoji) for reaction in message.reactions],
        }

    async def on_message(self, message):
        """Called for every message the bot can see"""
        # Don't respond to bot messages but still process commands
        await self.process_commands(message)
        
        if not message.author.bot:
            # Add message to cache with relevant metadata
            message_data = self.create_message_data(message)
            self.message_cache.append(message_data)

    # [Previous command methods remain the same...]
    # [Include collect_data, analyze_channel, and export_data methods from before]

def main():
    load_dotenv()
    
    # Get the bot token from environment variables
    TOKEN = os.getenv('DISCORD_TOKEN')
    
    if not TOKEN:
        print("Error: No Discord token found!")
        print("Please create a .env file with your bot token:")
        print("DISCORD_TOKEN=your_bot_token_here")
        return
    
    try:
        # Create and run the bot
        bot = MessageDataCollector()
        print("Starting bot...")
        bot.run(TOKEN)
    except discord.LoginFailure:
        print("Error: Invalid Discord token!")
        print("Please check your .env file and make sure the token is correct.")
    except Exception as e:
        print(f"Error starting bot: {str(e)}")

if __name__ == "__main__":
    main()