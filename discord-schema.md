# Discord Dataset JSON Schema

## Root Object
```json
{
  "type": "object",
  "required": ["guild", "channel", "dateRange", "exportedAt", "messages"],
  "properties": {
    "guild": {
      "type": "object",
      "required": ["id", "name"],
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string" },
        "iconUrl": { 
          "type": "string",
          "format": "uri"
        }
      }
    },
    "channel": {
      "type": "object",
      "required": ["id", "type", "name"],
      "properties": {
        "id": { "type": "string" },
        "type": { 
          "type": "string",
          "enum": ["GuildTextChat"]
        },
        "categoryId": { "type": "string" },
        "category": { "type": "string" },
        "name": { "type": "string" },
        "topic": { 
          "type": ["string", "null"]
        }
      }
    },
    "dateRange": {
      "type": "object",
      "properties": {
        "after": { 
          "type": "string",
          "format": "date-time"
        },
        "before": { 
          "type": ["string", "null"],
          "format": "date-time"
        }
      }
    },
    "exportedAt": { 
      "type": "string",
      "format": "date-time"
    },
    "messages": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Message"
      }
    }
  }
}
```

## Definitions

### Message Object
```json
{
  "type": "object",
  "required": ["id", "type", "timestamp", "content", "author"],
  "properties": {
    "id": { "type": "string" },
    "type": { 
      "type": "string",
      "enum": ["Default"]
    },
    "timestamp": { 
      "type": "string",
      "format": "date-time"
    },
    "timestampEdited": { 
      "type": ["string", "null"],
      "format": "date-time"
    },
    "callEndedTimestamp": { 
      "type": ["string", "null"],
      "format": "date-time"
    },
    "isPinned": { "type": "boolean" },
    "content": { "type": "string" },
    "author": {
      "$ref": "#/definitions/Author"
    },
    "attachments": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Attachment"
      }
    },
    "embeds": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Embed"
      }
    },
    "stickers": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Sticker"
      }
    },
    "reactions": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Reaction"
      }
    },
    "mentions": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Author"
      }
    }
  }
}
```

### Author Object
```json
{
  "type": "object",
  "required": ["id", "name"],
  "properties": {
    "id": { "type": "string" },
    "name": { "type": "string" },
    "discriminator": { "type": "string" },
    "nickname": { "type": "string" },
    "color": { 
      "type": "string",
      "pattern": "^#[0-9A-Fa-f]{6}$"
    },
    "isBot": { "type": "boolean" },
    "roles": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Role"
      }
    },
    "avatarUrl": { 
      "type": "string",
      "format": "uri"
    }
  }
}
```

### Role Object
```json
{
  "type": "object",
  "required": ["id", "name", "color", "position"],
  "properties": {
    "id": { "type": "string" },
    "name": { "type": "string" },
    "color": { 
      "type": "string",
      "pattern": "^#[0-9A-Fa-f]{6}$"
    },
    "position": { "type": "integer" }
  }
}
```

### Attachment Object
```json
{
  "type": "object",
  "required": ["id", "url", "fileName"],
  "properties": {
    "id": { "type": "string" },
    "url": { 
      "type": "string",
      "format": "uri"
    },
    "fileName": { "type": "string" },
    "fileSizeBytes": { "type": "integer" }
  }
}
```

### Embed Object
```json
{
  "type": "object",
  "properties": {
    "title": { "type": "string" },
    "description": { "type": "string" },
    "url": { 
      "type": "string",
      "format": "uri"
    },
    "timestamp": { 
      "type": "string",
      "format": "date-time"
    },
    "color": { "type": "integer" },
    "fields": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "value": { "type": "string" },
          "inline": { "type": "boolean" }
        }
      }
    }
  }
}
```

### Reaction Object
```json
{
  "type": "object",
  "required": ["emoji", "count"],
  "properties": {
    "emoji": {
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string" },
        "isAnimated": { "type": "boolean" }
      }
    },
    "count": { "type": "integer" }
  }
}
```

## Data Type Specifications

### Timestamps
- All timestamps are in ISO 8601 format
- Include timezone information (UTC)
- Example: `"2024-10-23T01:00:54.956+00:00"`

### IDs
- Represented as strings
- Discord snowflake format
- Example: `"1253563208833433701"`

### Colors
- Hexadecimal format for role and user colors
- Example: `"#2ECC71"`
- RGB integer format for embeds

### URLs
- Full URLs including protocol
- CDN URLs for Discord assets
- Example: `"https://cdn.discordapp.com/avatars/[user_id]/[hash].png?size=512"`

## Common Fields and Relationships

### User Identification
- Users can be identified by:
  - ID (unique)
  - Name
  - Discriminator
  - Nickname (optional)

### Role Hierarchy
- Roles have positions (integers)
- Higher position number = higher role
- Multiple roles per user possible

### Message References
- Messages can mention users
- Messages can have attachments
- Messages can have reactions
- Messages can be edited (tracked by timestampEdited)

### Bot Interaction
- isBot flag indicates bot accounts
- Bot messages follow same structure as user messages
- Bots can have roles and permissions