#!/usr/bin/env bash

DOTFILES_DIR="$HOME/dotfiles" # Adjust this path to your dotfiles repository
CONFIG_DIR="$HOME/.config"
SCRIPTS_DIR="$HOME/.scripts"
PACKAGE_LIST_DIR="$HOME/package_lists"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Read ignore list from .dotfilerc
IGNORE_LIST=()
if [ -f "$HOME/.dotfilerc" ]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed 's/#.*//g' | xargs) # Remove comments and trim whitespace
    [[ -z "$line" ]] && continue                  # Skip empty lines
    IGNORE_LIST+=("$line")
  done <"$HOME/.dotfilerc"
fi

# Function to create symlink
create_symlink() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ]; then
    if [ ! -L "$dest" ]; then
      local src_hash=$(md5sum "$src" | cut -d ' ' -f 1)
      local dest_hash=$(md5sum "$dest" | cut -d ' ' -f 1)

      if [ "$src_hash" != "$dest_hash" ]; then
        mv "$dest" "${dest}.backup"
        echo -e "${YELLOW}Moved existing file to ${dest}.backup${NC}"
      else
        echo -e "${GREEN}Files are identical, skipping: $dest${NC}"
        return
      fi
    else
      rm "$dest"
    fi
  fi

  ln -s "$src" "$dest"
  echo -e "${GREEN}Created symlink: $dest -> $src${NC}"
}

# Read ignore list from .dotfilerc
if [ -f "$HOME/.dotfilerc" ]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | xargs)                   # Trim whitespace
    [[ -z "$line" || "$line" == \#* ]] && continue # Skip empty lines and comments
    IGNORE_LIST+=("$line")
  done <"$HOME/.dotfilerc"
fi

# Function to handle config directory
handle_config_dir() {
  local REAL_CONFIG_DIR=$(realpath "$CONFIG_DIR")

  rg --files "$DOTFILES_DIR/config" | while read -r src; do
    local rel_path="${src#$DOTFILES_DIR/config/}"
    local dest="$REAL_CONFIG_DIR/$rel_path"

    mkdir -p "$(dirname "$dest")"
    create_symlink "$src" "$dest"
  done
}

# Function to handle scripts directory
handle_scripts_dir() {
  if [ ! -d "$SCRIPTS_DIR" ]; then
    mkdir -p "$SCRIPTS_DIR"
  fi

  rg --files "$DOTFILES_DIR/scripts" | while read -r src; do
    dest="$SCRIPTS_DIR/$(basename "$src")"
    create_symlink "$src" "$dest"
  done
}

# Function to handle package_list directory
handle_package_list_dir() {
  if [ ! -d "$PACKAGE_LIST_DIR" ]; then
    mkdir -p "$PACKAGE_LIST_DIR"
  fi

  rg --files "$DOTFILES_DIR/package_lists" --glob '*.list' | while read -r src; do
    dest="$PACKAGE_LIST_DIR/$(basename "$src")"
    create_symlink "$src" "$dest"
  done
}

# Function to handle zshrc
handle_zshrc() {
  create_symlink "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
}

# Function to check for new files in ~/.config and move them to dotfiles
check_new_config_files() {
  local REAL_CONFIG_DIR=$(realpath "$CONFIG_DIR")
  local new_files=()
  local batch_size=10

  # Use ripgrep to find files, respecting .dotfilerc
  while IFS= read -r file; do
    local rel_path="${file#$REAL_CONFIG_DIR/}"
    local dotfile_path="$DOTFILES_DIR/config/$rel_path"

    if [ ! -e "$dotfile_path" ]; then
      new_files+=("$file")
    fi
  done < <(rg --files "$CONFIG_DIR" --ignore-file "$HOME/.dotfilerc")

  # Process files in batches
  for ((i = 0; i < ${#new_files[@]}; i += batch_size)); do
    echo "Processing files $((i + 1)) to $((i + batch_size < ${#new_files[@]} ? i + batch_size : ${#new_files[@]})) of ${#new_files[@]}"

    for ((j = i; j < i + batch_size && j < ${#new_files[@]}; j++)); do
      file="${new_files[j]}"
      rel_path="${file#$REAL_CONFIG_DIR/}"
      echo -e "$((j - i + 1)). ${YELLOW}$rel_path${NC}"
    done

    echo "Enter the numbers of files you want to move (space-separated), or 'q' to quit:"
    read -r choice

    if [[ $choice == "q" ]]; then
      echo "Quitting file processing."
      return
    fi

    for num in $choice; do
      if [[ "$num" =~ ^[0-9]+$ ]] && ((num > 0 && num <= batch_size)); then
        index=$((i + num - 1))
        if ((index < ${#new_files[@]})); then
          file="${new_files[index]}"
          rel_path="${file#$REAL_CONFIG_DIR/}"
          dotfile_path="$DOTFILES_DIR/config/$rel_path"

          mkdir -p "$(dirname "$dotfile_path")"
          mv "$file" "$dotfile_path"
          create_symlink "$dotfile_path" "$file"
          echo -e "${GREEN}Moved and symlinked: $rel_path${NC}"
        fi
      else
        echo "Invalid number: $num. Skipping."
      fi
    done
  done
}

# Debug function
debug() {
  echo "DEBUG: $1" >&2
}

# Print ignore list for debugging
debug "Ignore list:"
for item in "${IGNORE_LIST[@]}"; do
  debug "  $item"
done

# Main execution
echo "Managing dotfiles..."

handle_config_dir
handle_scripts_dir
handle_package_list_dir
handle_zshrc
check_new_config_files

echo -e "${GREEN}Dotfile management completed.${NC}"
