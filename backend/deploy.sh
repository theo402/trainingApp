#!/bin/bash

# Training App Backend Deployment Script
set -e

echo "Starting Training App Backend deployment..."

# Install system dependencies
echo "Installing system dependencies..."
apt update
apt install -y postgresql postgresql-contrib curl

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Setup database
echo "Setting up database..."
sudo -u postgres psql -c "CREATE DATABASE training_app;" || echo "Database already exists"
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'password';"

# Setup environment
echo "Setting up environment..."
cp .env.production .env

# Install sqlx-cli if not present
if ! command -v sqlx &> /dev/null; then
    echo "Installing sqlx-cli..."
    cargo install sqlx-cli --no-default-features --features postgres
fi

# Run migrations
echo "Running database migrations..."
sqlx database create || echo "Database already exists"
sqlx migrate run

# Set permissions
chmod +x target/release/training_app_backend

echo "Deployment preparation complete!"
echo "To start the server, run: ./target/release/training_app_backend"