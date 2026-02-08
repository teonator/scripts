#!/usr/bin/env bash
set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# Configurable options
BREW_OPTIONS=(
  "visual-studio-code"
  "sublime-text"
  "sublime-merge"
  "google-chrome"
  "firefox"
  "iterm2"
  "docker"
  "docker-sync"
  "node"
  "ruby"
  "notion"
  "obsidian"
  "postman"
  "insomnia"
  "copilot"
  "codex"
  "claude"
  "gemini-cli"
  "sequel-ace"
  "ngrok"
)

DEFAULT_SELECTED=(
  "visual-studio-code"
  "google-chrome"
  "notion"
  "copilot"
)

ensure_xcode_cli_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi

  echo "Xcode Command Line Tools not found. Installing..."
  xcode-select --install

  echo
  echo "After the installer finishes, run this script again."
  exit 1
}

ensure_brew() {
  if need_cmd brew; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi

  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

ensure_gum() {
  if need_cmd gum; then
    return
  fi
  echo "gum not found. Installing gum..."
  brew install gum
}

brew_install() {
  local pkg="$1"
  brew install "$pkg"
  # brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
}

ensure_xcode_cli_tools
ensure_brew
ensure_gum

gum_default_args=()
for pkg in "${DEFAULT_SELECTED[@]}"; do
  gum_default_args+=( --selected "$pkg" )
done

selected=$(
  gum choose --no-limit \
    --cursor="> " \
    --cursor-prefix="[ ] " \
    --selected-prefix="[X] " \
    --unselected-prefix="[ ] " \
    "${gum_default_args[@]}" \
    "${BREW_OPTIONS[@]}"
)

if [[ -z "${selected// }" ]]; then
  gum style --foreground 244 "No options selected."
  exit 0
fi

gum style --border rounded --padding "0 1" --margin "1 0" \
  "$(printf "%s\n" "$selected" | sed 's/^/• /')"

if ! gum confirm "Proceed to install these packages?"; then
  gum style --foreground 244 "Cancelled."
  exit 0
fi

while IFS= read -r pkg; do
  [[ -z "${pkg// }" ]] && continue
  echo "❯ brew install $pkg"
  brew_install "$pkg"
  echo
done <<< "$selected"

echo "Done."
