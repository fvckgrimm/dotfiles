#!/usr/bin/env bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Array to store failed installations
declare -A failed_installs

# Function to install a package
install_package() {
  local package=$1
  local package_manager=$2

  echo -e "${YELLOW}Installing $package using $package_manager...${NC}"

  case $package_manager in
  pacman)
    sudo pacman -S --noconfirm "$package"
    ;;
  yay)
    yay -S --noconfirm "$package"
    ;;
  nix)
    nix-env -iA nixpkgs."$package"
    ;;
  *)
    echo -e "${RED}Unknown package manager: $package_manager${NC}"
    return 1
    ;;
  esac

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully installed $package${NC}"
  else
    echo -e "${RED}Failed to install $package${NC}"
  fi
}

# Function to read and install packages from a file
install_from_file() {
  local file=$1
  local package_manager=$2

  if [ ! -f "$file" ]; then
    echo -e "${RED}File not found: $file${NC}"
    return 1
  fi

  echo -e "${YELLOW}Installing packages from $file using $package_manager${NC}"

  while IFS= read -r package || [[ -n "$package" ]]; do
    # Skip empty lines and comments
    [[ -z "$package" || "$package" == \#* ]] && continue
    if ! install_package "$package" "$package_manager"; then
      failed_installs["$package"]=$package_manager
    fi
  done <"$file"
}

# Function to retry failed installations
retry_failed_installs() {
  if [ ${#failed_installs[@]} -eq 0 ]; then
    echo -e "${GREEN}No failed installations to retry.${NC}"
    return
  fi

  echo -e "${YELLOW}The following packages failed to install:${NC}"
  for package in "${!failed_installs[@]}"; do
    echo "$package (tried with ${failed_installs[$package]})"
  done

  read -p "Do you want to retry installing these packages with a different package manager? (y/n): " retry_choice
  if [[ $retry_choice != "y" && $retry_choice != "Y" ]]; then
    return
  fi

  echo "Choose a package manager for retry:"
  echo "1) pacman"
  echo "2) yay"
  echo "3) nix"
  read -p "Enter your choice (1-3): " pm_choice

  case $pm_choice in
  1) retry_package_manager="pacman" ;;
  2) retry_package_manager="yay" ;;
  3) retry_package_manager="nix" ;;
  *)
    echo -e "${RED}Invalid choice. Skipping retry.${NC}"
    return
    ;;
  esac

  for package in "${!failed_installs[@]}"; do
    if install_package "$package" "$retry_package_manager"; then
      unset failed_installs["$package"]
    fi
  done

  if [ ${#failed_installs[@]} -gt 0 ]; then
    echo -e "${YELLOW}Some packages still failed to install:${NC}"
    for package in "${!failed_installs[@]}"; do
      echo "$package"
    done
  else
    echo -e "${GREEN}All previously failed packages have been successfully installed.${NC}"
  fi
}

# Main script

# Prompt for package manager
echo "Choose a package manager:"
echo "1) pacman"
echo "2) yay"
echo "3) nix"
read -p "Enter your choice (1-3): " pm_choice

case $pm_choice in
1) package_manager="pacman" ;;
2) package_manager="yay" ;;
3) package_manager="nix" ;;
*)
  echo -e "${RED}Invalid choice. Exiting.${NC}"
  exit 1
  ;;
esac

# Directory containing package lists
lists_dir="$HOME/package_lists"

# Check if the directory exists
if [ ! -d "$lists_dir" ]; then
  echo -e "${RED}Directory not found: $lists_dir${NC}"
  exit 1
fi

# Install from each list file
for list_file in "$lists_dir"/*.list; do
  if [ -f "$list_file" ]; then
    echo -e "${YELLOW}Found list: $list_file${NC}"
    read -p "Do you want to install packages from this list? (y/n): " install_choice
    if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
      install_from_file "$list_file" "$package_manager"
    else
      echo -e "${YELLOW}Skipping $list_file${NC}"
    fi
  fi
done

# Retry failed installations
retry_failed_installs

echo -e "${GREEN}Installation process completed.${NC}"
