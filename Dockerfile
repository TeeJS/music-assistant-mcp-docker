# Stage 1: Build with uv
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

WORKDIR /app

# Copy dependency files first for layer caching
COPY pyproject.toml uv.lock ./

# Install dependencies only (no project yet)
RUN uv sync --frozen --no-install-project

# Copy source code and README (needed by hatchling for metadata)
COPY src/ src/
COPY README.md ./

# Install the project itself
RUN uv sync --frozen

# Stage 2: Slim runtime
FROM python:3.11-slim-bookworm

WORKDIR /app

# Copy the virtual environment from builder
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
