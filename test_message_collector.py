import discord
from discord.ext import commands
import pandas as pd
from datetime import datetime, timedelta
import asyncio
import json

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
        print(f'{self.user} has connected to Discord!')
        print(f'Bot is in {len(self.guilds)} guilds')

    async def on_message(self, message):
        """Called for every message the bot can see"""
        # Don't respond to bot messages
        if message.author.bot:
            return

        # Process commands
        await self.process_commands(message)
        
        # Add message to cache with relevant metadata
        message_data = {
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
        self.message_cache.append(message_data)

    async def collect_data(self, ctx, limit: int = 100):
        """Command to collect historical message data"""
        try:
            messages = []
            async for message in ctx.channel.history(limit=limit):
                message_data = {
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
                messages.append(message_data)
            
            await ctx.send(f'Collected {len(messages)} messages from channel')
            return messages
            
        except discord.Forbidden:
            await ctx.send("I don't have permission to read message history!")
        except Exception as e:
            await ctx.send(f"An error occurred: {str(e)}")

    async def analyze_channel(self, ctx, hours: int = 24):
        """Analyze channel activity for the past X hours"""
        try:
            after_time = datetime.utcnow() - timedelta(hours=hours)
            messages = []
            
            async for message in ctx.channel.history(after=after_time):
                messages.append(message)
            
            # Basic analysis
            total_messages = len(messages)
            unique_authors = len(set(msg.author.id for msg in messages))
            bot_messages = len([msg for msg in messages if msg.author.bot])
            
            analysis = f"""Channel Analysis (Past {hours} hours):
            Total Messages: {total_messages}
            Unique Authors: {unique_authors}
            Bot Messages: {bot_messages}
            Human Messages: {total_messages - bot_messages}
            """
            
            await ctx.send(analysis)
            
        except discord.Forbidden:
            await ctx.send("I don't have permission to read message history!")
        except Exception as e:
            await ctx.send(f"An error occurred: {str(e)}")

    async def export_data(self, ctx, format: str = 'json'):
        """Export collected message data"""
        if not self.message_cache:
            await ctx.send("No messages in cache to export!")
            return
            
        try:
            if format.lower() == 'csv':
                df = pd.DataFrame(self.message_cache)
                df.to_csv('message_data.csv', index=False)
                await ctx.send("Data exported to message_data.csv", 
                             file=discord.File('message_data.csv'))
                
            else:  # default to JSON
                with open('message_data.json', 'w') as f:
                    json.dump(self.message_cache, f, indent=2)
                await ctx.send("Data exported to message_data.json", 
                             file=discord.File('message_data.json'))
                
        except Exception as e:
            await ctx.send(f"Error exporting data: {str(e)}")

# Example usage:
"""
# Create a .env file with your bot token:
DISCORD_TOKEN=your_bot_token_here

# Run the bot:
"""
import os
from dotenv import load_dotenv

load_dotenv()
bot = MessageDataCollector()
bot.run(os.getenv('DISCORD_TOKEN'))
"""
# Commands available in Discord:
!collect 100  # Collect last 100 messages
!analyze 24   # Analyze last 24 hours
!export csv   # Export data to CSV
"""