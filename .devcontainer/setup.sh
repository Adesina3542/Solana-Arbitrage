#!/bin/bash

# Solana Arbitrage Development Environment Setup for GitHub Codespaces
# This script handles common version conflicts and SSL issues

set -e

echo "🚀 Setting up Solana development environment for arbitrage bot..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update system packages
print_status "Updating system packages..."
sudo apt-get update -y
sudo apt-get install -y curl wget build-essential pkg-config libssl-dev libudev-dev

# Install Node.js (required for some Anchor operations)
print_status "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Rust with specific version that works well with Solana
print_status "Installing Rust 1.79.0 (stable version that works with both Anchor and Solana)..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.79.0
source ~/.cargo/env

# Add wasm32 target (needed for some Solana operations)
rustup target add wasm32-unknown-unknown

print_status "Rust version: $(rustc --version)"

# Install Solana CLI from GitHub releases (avoids SSL issues)
print_status "Installing Solana CLI v1.18.26 from GitHub releases..."
SOLANA_VERSION="v1.18.26"
SOLANA_ARCHIVE="solana-release-x86_64-unknown-linux-gnu.tar.bz2"

# Create solana directory
mkdir -p ~/.local/share/solana/install/active_release/bin

# Download and extract Solana
cd /tmp
wget -q "https://github.com/solana-labs/solana/releases/download/v1.18.26/solana-release-x86_64-unknown-linux-gnu.tar.bz2"
tar -xjf "solana-release-x86_64-unknown-linux-gnu.tar.bz2"

# Move binaries to the correct location
cp solana-release/bin/* ~/.local/share/solana/install/active_release/bin/

# Add Solana to PATH
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

print_status "Solana CLI version: $(solana --version)"

# Configure Solana for devnet
print_status "Configuring Solana for devnet..."
solana config set --url devnet
solana config set --keypair ~/.config/solana/id.json

# Generate keypair if it doesn't exist
if [ ! -f ~/.config/solana/id.json ]; then
    print_status "Generating new Solana keypair..."
    solana-keygen new --no-bip39-passphrase --outfile ~/.config/solana/id.json
fi

# Install Anchor CLI with compatible version
print_status "Installing Anchor CLI v0.30.1..."

# Use cargo to install Anchor (more reliable than avm in Codespaces)
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install 0.30.1
avm use 0.30.1

# Verify installations
print_status "Verifying installations..."
echo "=== Version Information ==="
echo "Rust: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Solana: $(solana --version)"
echo "Anchor: $(anchor --version)"

# Test cargo-build-sbf
print_status "Testing cargo-build-sbf..."
cargo-build-sbf --version

# Create a sample Anchor project to test everything works
print_status "Creating test Anchor project..."
cd /tmp
anchor init test_project --no-git
cd test_project

# Test anchor build
print_status "Testing anchor build..."
anchor build

print_status "✅ Environment setup complete!"
print_status "🎯 Ready for Solana arbitrage development!"

echo ""
echo "=== Next Steps ==="
echo "1. Create your arbitrage project: anchor init my_arbitrage_bot"
echo "2. Add flash loan dependencies to Cargo.toml"
echo "3. Start building your arbitrage smart contract"
echo ""
echo "=== Useful Commands ==="
echo "- Get devnet SOL: solana airdrop 2"
echo "- Check balance: solana balance"
echo "- Build program: anchor build"
echo "- Test program: anchor test"
echo "- Deploy program: anchor deploy"
