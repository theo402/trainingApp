#!/bin/bash

# Training App Backend Deployment Script for Arch Linux
set -e

echo "Starting Training App Backend deployment on Arch Linux..."

# Install system dependencies
echo "Installing system dependencies..."
pacman -Sy --noconfirm postgresql curl

# Initialize and start PostgreSQL
echo "Setting up PostgreSQL..."
sudo -u postgres initdb -D /var/lib/postgres/data || echo "Database already initialized"
systemctl start postgresql
systemctl enable postgresql

# Setup database
echo "Setting up database..."
sudo -u postgres psql -c "CREATE DATABASE training_app;" || echo "Database already exists"
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'password';"

# Setup environment
echo "Setting up environment..."
cp .env.production .env

# Set permissions
chmod +x target/release/training_app_backend

echo "Deployment preparation complete!"
echo "To start the server, run: ./target/release/training_app_backend"