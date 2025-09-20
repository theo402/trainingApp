# Multi-stage build for Rust application
FROM rust:1.75 as builder

WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime image
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary
COPY --from=builder /app/target/release/training_app_backend .
COPY --from=builder /app/migrations ./migrations
COPY .env.production .env

# Create a non-root user
RUN useradd -r -s /bin/false appuser
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 3000

CMD ["./training_app_backend"]