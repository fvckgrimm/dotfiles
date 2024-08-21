#!/usr/bin/env bash

# Set default character for lil-guy
DEFAULT_CHARACTER="zero"

VENV_DIR="$HOME/python/.venv"

# Parse command-line options
while getopts "c:" opt; do
  case $opt in
  c) DEFAULT_CHARACTER="$OPTARG" ;;
  *)
    echo "Usage: $0 [-c character] [command]" >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

create_venv() {
  local venv_name="$1"
  local venv_path="$VENV_DIR/$venv_name"
  if [ ! -d "$VENV_DIR" ]; then
    mkdir -p "$VENV_DIR"
  fi
  python3 -m venv "$venv_path"
  echo "$venv_name" # Return only the name, not the full path
}

activate_venv() {
  local venv_name=$1
  local venv_path="$VENV_DIR/$venv_name"
  echo "source $venv_path/bin/activate"
}

list_venvs() {
  ls -1 "$VENV_DIR"
}

select_or_create_venv() {
  local venvs=($(list_venvs) "Create new")
  local selected_venv=$(gum choose "${venvs[@]}")
  if [ "$selected_venv" = "Create new" ]; then
    local new_venv=$(gum input --placeholder "Enter new venv name")
    create_venv "$new_venv"
    echo "$new_venv"
  else
    echo "$selected_venv"
  fi
}

install_command() {
  if gum confirm "Do you want to use a virtual environment?"; then
    local venv=$(select_or_create_venv)
    if [ -d "$VENV_DIR/$venv" ]; then
      # Activate the virtual environment
      source "$VENV_DIR/$venv/bin/activate"

      # Start lil-guy in the background
      lil-guy -message "Installing packages..." -character "$DEFAULT_CHARACTER" &
      LIL_GUY_PID=$!

      # Run the installation
      command pip install "$@"

      # Stop lil-guy
      kill $LIL_GUY_PID

      # Deactivate the virtual environment
      deactivate
    else
      echo "Failed to create or find virtual environment"
      exit 1
    fi
  else
    # Start lil-guy in the background
    lil-guy -message "Installing packages..." -character "$DEFAULT_CHARACTER" &
    LIL_GUY_PID=$!

    # Run the installation
    command pip install "$@"

    # Stop lil-guy
    kill $LIL_GUY_PID
  fi
}

venv_command() {
  local subcmd="$1"
  shift
  case "$subcmd" in
  activate)
    local venv=$(select_or_create_venv)
    echo "source $VENV_DIR/$venv/bin/activate"
    ;;
  deactivate)
    echo 'deactivate 2>/dev/null || echo "No active virtual environment"'
    ;;
  list)
    list_venvs
    ;;
  *)
    echo "Invalid venv subcommand: $subcmd"
    echo "Available subcommands: activate, deactivate, list"
    exit 1
    ;;
  esac
}

main() {
  local cmd="$1"
  shift
  case "$cmd" in
  install)
    install_command "$@"
    ;;
  venv)
    venv_command "$@"
    ;;
  *)
    command pip "$cmd" "$@"
    ;;
  esac
}

main "$@"
