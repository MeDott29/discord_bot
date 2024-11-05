import discord
from discord.ext import commands
import pandas as pd
from datetime import datetime, timedelta
import asyncio
import json
import os
from dotenv import load_dotenv

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

    async def collect_data(self, ctx, limit: int = 100):
        """Command to collect historical message data"""
        try:
            message_count = 0
            async for message in ctx.channel.history(limit=limit):
                if not message.author.bot:  # Skip bot messages
                    message_data = self.create_message_data(message)
                    self.message_cache.append(message_data)
                    message_count += 1
            
            await ctx.send(f'Collected {message_count} messages from channel. Total messages in cache: {len(self.message_cache)}')
            
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
            human_messages = total_messages - bot_messages
            
            # Additional analysis from cache
            cache_analysis = ""
            if self.message_cache:
                df = pd.DataFrame(self.message_cache)
                if not df.empty:
                    avg_mentions = df['mentions'].mean()
                    avg_attachments = df['attachments'].mean()
                    cache_analysis = f"""
            Average Mentions per Message: {avg_mentions:.2f}
            Average Attachments per Message: {avg_attachments:.2f}
            Messages in Cache: {len(self.message_cache)}"""
            
            analysis = f"""Channel Analysis (Past {hours} hours):
            Total Messages: {total_messages}
            Unique Authors: {unique_authors}
            Bot Messages: {bot_messages}
            Human Messages: {human_messages}{cache_analysis}
            """
            
            await ctx.send(analysis)
            
        except discord.Forbidden:
            await ctx.send("I don't have permission to read message history!")
        except Exception as e:
            await ctx.send(f"An error occurred: {str(e)}")

    async def export_data(self, ctx, format: str = 'json'):
        """Export collected message data"""
        if not self.message_cache:
            await ctx.send("No messages in cache to export! Use !collect first to gather some messages.")
            return
            
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            if format.lower() == 'csv':
                filename = f'message_data_{timestamp}.csv'
                df = pd.DataFrame(self.message_cache)
                df.to_csv(filename, index=False)
                await ctx.send(f"Data exported to {filename} ({len(self.message_cache)} messages)", 
                             file=discord.File(filename))
                
            else:  # default to JSON
                filename = f'message_data_{timestamp}.json'
                with open(filename, 'w') as f:
                    json.dump(self.message_cache, f, indent=2)
                await ctx.send(f"Data exported to {filename} ({len(self.message_cache)} messages)", 
                             file=discord.File(filename))
                
        except Exception as e:
            await ctx.send(f"Error exporting data: {str(e)}")

def main():
    # Load environment variables from .env file
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