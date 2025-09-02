#!/bin/bash

# Fix Git Divergence Script for Olym3 Testnet Season 3
# This script helps resolve Git branch divergence issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header "Git Divergence Resolution"

# Check current status
print_status "Current Git status:"
git status --short

echo ""
print_status "Current branch: $(git branch --show-current)"
print_status "Upstream remote: $(git remote get-url upstream 2>/dev/null || echo 'Not configured')"

echo ""
print_warning "You have divergent branches. Choose how to resolve:"
echo "1. Rebase (recommended) - Replay your changes on top of upstream"
echo "2. Merge - Create a merge commit"
echo "3. Reset - Discard local changes and use upstream exactly"
echo "4. Manual - Exit and resolve manually"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        print_status "Attempting rebase..."
        if git pull --rebase upstream main; then
            print_status "Rebase successful!"
        else
            print_error "Rebase failed. You may need to resolve conflicts manually."
            print_status "After resolving conflicts, run: git rebase --continue"
            exit 1
        fi
        ;;
    2)
        print_status "Attempting merge..."
        if git pull upstream main --no-edit; then
            print_status "Merge successful!"
        else
            print_error "Merge failed. You may need to resolve conflicts manually."
            print_status "After resolving conflicts, run: git commit"
            exit 1
        fi
        ;;
    3)
        print_warning "This will discard ALL local changes!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            print_status "Resetting to upstream main..."
            git fetch upstream
            git reset --hard upstream/main
            print_status "Reset complete!"
        else
            print_status "Reset cancelled."
            exit 0
        fi
        ;;
    4)
        print_status "Exiting for manual resolution."
        print_status "You can run these commands manually:"
        echo "  git pull --rebase upstream main  # For rebase"
        echo "  git pull upstream main           # For merge"
        echo "  git reset --hard upstream/main   # For reset"
        exit 0
        ;;
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

print_status "Git divergence resolved!"
print_status "You can now continue with: ./setup-erigon-fork.sh"
