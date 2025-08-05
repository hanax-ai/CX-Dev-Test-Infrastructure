#!/bin/bash

# group_vars Directory Cleanup Script
# Aligns group_vars structure with corrected inventory hosts file
# CX R&D Infrastructure - August 4, 2025

# Set root directory of your Ansible configs
ROOT="/opt/CX-Dev-Test-Infrastructure/configs/ansible"
GVAR="$ROOT/group_vars"

echo "📁 Starting group_vars cleanup and alignment..."
echo "Root directory: $ROOT"
echo "Group vars directory: $GVAR"
echo ""

# Check if group_vars directory exists
if [ ! -d "$GVAR" ]; then
    echo "❌ Error: $GVAR directory not found!"
    exit 1
fi

# Show current state
echo "📋 Current group_vars structure:"
ls -la "$GVAR"
echo ""

# Mapping of old group names to new corrected ones
declare -A GROUP_MAP=(
  ["cx_web_servers"]="web_ui_servers"
  ["cx_api_servers"]="api_gateway_servers"
  ["cx_database_servers"]="database_servers"
  ["cx_vector_db_servers"]="vector_database_servers"
  ["cx_llm_servers"]="llm_server_chat_servers"
  ["orchestration"]="orchestration_servers"
  ["cx_test_servers"]="test_servers"
  ["cx_dev_servers"]="development_servers"
  ["cx_devops_servers"]="devops_servers"
  ["cx_metric_servers"]="metrics_servers"
)

# Create backup directory with timestamp
BACKUP_DIR="$GVAR/backup_$(date +%Y%m%d_%H%M%S)"
echo "💾 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Preview changes first
echo ""
echo "🔍 Preview of planned changes:"
echo "================================"

for OLD in "${!GROUP_MAP[@]}"; do
  OLD_PATH="$GVAR/$OLD"
  NEW_PATH="$GVAR/${GROUP_MAP[$OLD]}"
  
  if [ -d "$OLD_PATH" ]; then
    echo "🔁 Would move: $OLD → ${GROUP_MAP[$OLD]}"
  fi
done

# Check for unmatched directories
echo ""
echo "📦 Directories that will be archived:"
for DIR in "$GVAR"/*; do
  if [ -d "$DIR" ]; then
    BASENAME=$(basename "$DIR")
    # Skip 'all' directory and backup directories
    if [[ "$BASENAME" != "all" && "$BASENAME" != "backup_"* ]]; then
      # Check if this directory is in our mapping (either as old or new name)
      FOUND=false
      for OLD in "${!GROUP_MAP[@]}"; do
        if [[ "$BASENAME" == "$OLD" || "$BASENAME" == "${GROUP_MAP[$OLD]}" ]]; then
          FOUND=true
          break
        fi
      done
      
      if [ "$FOUND" = false ]; then
        echo "📦 Will archive: $BASENAME"
      fi
    fi
  fi
done

echo ""
read -p "🤔 Proceed with these changes? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled by user."
    rmdir "$BACKUP_DIR" 2>/dev/null
    exit 0
fi

echo ""
echo "🚀 Executing group_vars cleanup..."
echo "================================="

# Rename/move directories
for OLD in "${!GROUP_MAP[@]}"; do
  OLD_PATH="$GVAR/$OLD"
  NEW_PATH="$GVAR/${GROUP_MAP[$OLD]}"
  
  if [ -d "$OLD_PATH" ]; then
    echo "🔁 Moving $OLD → ${GROUP_MAP[$OLD]}"
    
    # If destination exists, backup it first
    if [ -d "$NEW_PATH" ]; then
      echo "   ⚠️  Destination exists, backing up first..."
      mv "$NEW_PATH" "$BACKUP_DIR/$(basename "$NEW_PATH")_existing"
    fi
    
    # Move to new path
    mv "$OLD_PATH" "$NEW_PATH"
    echo "   ✅ Successfully moved"
  else
    echo "   ℹ️  Directory $OLD not found, skipping"
  fi
done

# Archive leftover unmatched directories
echo ""
echo "📦 Archiving unmatched directories..."
for DIR in "$GVAR"/*; do
  if [ -d "$DIR" ]; then
    BASENAME=$(basename "$DIR")
    
    # Skip 'all' directory and backup directories
    if [[ "$BASENAME" != "all" && "$BASENAME" != "backup_"* ]]; then
      # Check if this directory should remain (is a target in our mapping)
      SHOULD_REMAIN=false
      for NEW in "${GROUP_MAP[@]}"; do
        if [[ "$BASENAME" == "$NEW" ]]; then
          SHOULD_REMAIN=true
          break
        fi
      done
      
      if [ "$SHOULD_REMAIN" = false ]; then
        echo "📦 Archiving unmatched: $BASENAME → backup/"
        mv "$DIR" "$BACKUP_DIR/$BASENAME"
      fi
    fi
  fi
done

echo ""
echo "📋 Final group_vars structure:"
echo "=============================="
ls -la "$GVAR"

echo ""
echo "✅ group_vars re-alignment complete!"
echo "💾 Backup created at: $BACKUP_DIR"
echo ""
echo "🎯 Your group_vars now align with the corrected inventory groups:"
echo "   - web_ui_servers"
echo "   - api_gateway_servers" 
echo "   - database_servers"
echo "   - vector_database_servers"
echo "   - llm_server_chat_servers"
echo "   - llm_server_instruct_servers"
echo "   - orchestration_servers"
echo "   - test_servers"
echo "   - development_servers"
echo "   - devops_servers"
echo "   - metrics_servers"
echo "   - all (global variables)"
