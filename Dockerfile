# Stage 1: Build with uv
FROM python:3.11-slim-bookworm AS builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy dependency files first for layer caching
COPY pyproject.toml uv.lock ./

# Create venv using the system Python so paths match the runtime stage
RUN uv venv .venv && uv sync --frozen --no-install-project

# Copy source code and README (needed by hatchling for metadata)
COPY src/ src/
COPY README.md ./

# Install the project itself (--no-editable so it copies into site-packages
# rather than linking back to src/ which won't exist in the runtime stage)
RUN uv sync --frozen --no-editable

# Stage 2: Slim runtime
FROM python:3.11-slim-bookworm

WORKDIR /app

# Copy the virtual environment from builder (Python paths match since same base image)
COPY --from=builder /app/.venv .venv/

# Use the venv's Python and scripts
ENV PATH="/app/.venv/bin:$PATH"

# Default to SSE transport for Docker deployments
ENV MCP_TRANSPORT=sse
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8000

EXPOSE 8000

# TCP socket health check — SSE endpoint would hang on HTTP GET
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import socket; s=socket.create_connection(('localhost', 8000), timeout=5); s.close()"

CMD ["music-assistant-mcp"]
