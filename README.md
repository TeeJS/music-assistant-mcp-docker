# Music Assistant MCP Server

An MCP (Model Context Protocol) server for controlling [Music Assistant](https://music-assistant.io/) - manage multi-room audio, playback queues, and search across music providers.

## Prerequisites

- A running [Music Assistant](https://music-assistant.io/) server
- A long-lived access token (Settings > Users > Long-lived access token)
- [uv](https://docs.astral.sh/uv/) installed

## Installation

No local installation required. Configure your MCP client to run directly from GitHub using `uvx`:

```json
{
  "mcpServers": {
    "music-assistant": {
      "command": "uvx",
      "args": [
        "--from", "git+https://github.com/davidpadbury/music-assistant-mcp",
        "music-assistant-mcp"
      ],
      "env": {
        "MUSIC_ASSISTANT_URL": "http://your-server:8095",
        "MUSIC_ASSISTANT_TOKEN": "your_token_here"
      }
    }
  }
}
```

Add this configuration to:
- **Claude Desktop**: `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows)
- **Claude Code**: `~/.claude.json`
- **Cursor**: Settings > MCP

## Quick Start

1. **List available speakers**: Use `ma_list_players` to see all speakers and their current state
2. **Search for music**: Use `ma_search` with a query to find songs, albums, artists, or playlists
3. **Play music**: Use `ma_play_media` with the URI from search results and a player ID
4. **Control playback**: Use `ma_playback` to play, pause, skip, or seek

## Available Tools

### Player Tools

| Tool | Purpose |
|------|---------|
| `ma_list_players` | List all speakers with volume, state, and group info |
| `ma_volume` | Set volume level (0-100), adjust up/down, or mute/unmute |
| `ma_group` | Group speakers together or ungroup them |

### Playback Tools

| Tool | Purpose |
|------|---------|
| `ma_playback` | Control playback: play, pause, stop, toggle, next, previous, seek |
| `ma_play_media` | Play media URIs on a player with queue options (play, replace, next, add) |

### Queue Tools

| Tool | Purpose |
|------|---------|
| `ma_queue` | Get queue contents, set shuffle/repeat, or clear the queue |
| `ma_queue_item` | Move or remove specific items in the queue |
| `ma_transfer_queue` | Transfer playback from one player to another |

### Music Library Tools

| Tool | Purpose |
|------|---------|
| `ma_search` | Search for artists, albums, tracks, playlists, or radio stations |
| `ma_browse` | Browse music provider content hierarchically |

## Common Workflows

### Play Music on a Speaker

```
1. ma_list_players()                           → Get player IDs
2. ma_search(query="Beatles Abbey Road")       → Find the album, get URI
3. ma_play_media(queue_id="living_room", media="spotify://album/xxx")
```

### Group Speakers for Multi-Room Audio

```
1. ma_list_players()                           → See available speakers
2. ma_group(action="join", player_ids=["kitchen", "bedroom"], target_player_id="living_room")
3. Now all three speakers play in sync
```

### Add to the Current Queue

```
1. ma_search(query="Bohemian Rhapsody", media_types=["track"])
2. ma_play_media(queue_id="living_room", media="spotify://track/xxx", option="add")
```

### Control What's Playing

```
- Pause: ma_playback(queue_id="living_room", command="pause")
- Skip: ma_playback(queue_id="living_room", command="next")
- Volume: ma_volume(player_id="living_room", level=50)
```

### Transfer Playback to Another Room

```
ma_transfer_queue(source_queue_id="living_room", target_queue_id="kitchen")
→ Music moves to kitchen, continuing from the same position
```

## Understanding IDs

- **player_id**: Identifies a speaker (e.g., "living_room"). Get from `ma_list_players`
- **queue_id**: Usually the same as player_id. Each player has its own queue
- **item_id**: Identifies a track in a queue. Get from `ma_queue`
- **URI**: Identifies a media item (e.g., "spotify://track/abc123"). Get from `ma_search` or `ma_browse`

## Tips

- Always call `ma_list_players` first to discover available speakers and their IDs
- Use `ma_search` to find media before trying to play it
- When grouping speakers, the `target_player_id` becomes the group leader
- Queue IDs are typically the same as player IDs
- Use `option="add"` with `ma_play_media` to add to queue without interrupting current playback

## Docker / Unraid Deployment

Run the MCP server as a Docker container so remote MCP clients can connect over the network via SSE.

### Quick Start with Docker Compose

1. Create a `.env` file:

```
MUSIC_ASSISTANT_URL=http://192.168.1.100:8095
MUSIC_ASSISTANT_TOKEN=your_token_here
```

2. Start the container:

```bash
docker compose up -d
```

The SSE endpoint will be available at `http://<host>:8000/sse`.

### Pull from GHCR

```bash
docker pull ghcr.io/teejs/music-assistant-mcp-docker:latest
```

Or run directly:

```bash
docker run -d \
  --name music-assistant-mcp \
  -p 8000:8000 \
  -e MUSIC_ASSISTANT_URL=http://192.168.1.100:8095 \
  -e MUSIC_ASSISTANT_TOKEN=your_token_here \
  ghcr.io/teejs/music-assistant-mcp-docker:latest
```

### Unraid Setup

In the Unraid Docker UI:

1. **Repository**: `ghcr.io/teejs/music-assistant-mcp-docker:latest`
2. **Port mapping**: Container port `8000` -> Host port `8000`
3. **Environment variables**:
   - `MUSIC_ASSISTANT_URL` = `http://<your-unraid-ip>:8095` (or wherever Music Assistant is running)
   - `MUSIC_ASSISTANT_TOKEN` = your long-lived access token

**Networking note**: If Music Assistant runs on the same Unraid server, use the host IP address (e.g., `http://192.168.1.100:8095`), not `localhost`, since the container uses bridge networking by default.

### Client Configuration (Remote SSE)

Configure your MCP client to connect to the SSE endpoint:

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "music-assistant": {
      "url": "http://<unraid-ip>:8000/sse"
    }
  }
}
```

**Claude Code** (`.mcp.json`):

```json
{
  "mcpServers": {
    "music-assistant": {
      "url": "http://<unraid-ip>:8000/sse"
    }
  }
}
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MUSIC_ASSISTANT_URL` | *(required)* | URL of your Music Assistant server |
| `MUSIC_ASSISTANT_TOKEN` | *(optional)* | Long-lived access token |
| `MCP_TRANSPORT` | `sse` (Docker) / `stdio` (local) | Transport protocol |
| `MCP_HOST` | `0.0.0.0` (Docker) / `127.0.0.1` (local) | Listen address |
| `MCP_PORT` | `8000` | Listen port |

## License

MIT
