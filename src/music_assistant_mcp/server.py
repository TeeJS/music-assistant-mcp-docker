"""Music Assistant MCP Server.

Provides tools for controlling Music Assistant through the Model Context Protocol.
"""

import os

from mcp.server.fastmcp import FastMCP

from .client import get_client
from .tools import music, playback, players, queue

# Create the MCP server
# Note: FastMCP's FASTMCP_HOST/FASTMCP_PORT env vars don't work because the
# constructor's default parameter values take precedence over pydantic_settings.
# We read our own env vars and pass them explicitly.
mcp = FastMCP(
    "music-assistant",
    host=os.environ.get("MCP_HOST", "127.0.0.1"),
    port=int(os.environ.get("MCP_PORT", "8000")),
)

# Register tools from each module
players.register_tools(mcp, get_client)
playback.register_tools(mcp, get_client)
queue.register_tools(mcp, get_client)
music.register_tools(mcp, get_client)


def main():
    """Run the MCP server."""
    transport = os.environ.get("MCP_TRANSPORT", "stdio")
    mcp.run(transport=transport)


if __name__ == "__main__":
    main()
