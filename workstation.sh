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
  "affine"
  "postman"
  "insomnia"
  "copilot-cli"
  "codex"
  "claude-code"
  "gemini-cli"
  "sequel-ace"
  "ngrok"
)

BREW__DEFAULT_SELECTED=(
  "visual-studio-code"
  "google-chrome"
  "notion"
  "copilot-cli"
)

VSCODE_OPTIONS=(
  "ms-vscode-remote.remote-ssh (Remote - SSH)"
  "ms-vscode-remote.remote-ssh-edit (Remote - SSH: Editing Configuration Files)"
  "ms-vscode.remote-explorer (Remote - Explorer)"
  "ms-vscode-remote.remote-containers (Dev Containers)"
  "ms-azuretools.vscode-containers (Docker)"
  "ms-kubernetes-tools.vscode-kubernetes-tools (Kubernetes Tools)"
  "xdebug.php-debug (PHP Debug)"
  "devsense.composer-php-vscode (PHP Composer)"
  "devsense.phptools-vscode (PHP Tools)"
  "devsense.profiler-php-vscode (PHP Profiler)"
  "devsense.intelli-php-vscode (IntelliPHP)"
  "laravel.vscode-laravel (Laravel)"
  "ryannaddy.laravel-artisan (Laravel Artisan)"
  "onecentlin.laravel5-snippets (Laravel Snippets)"
  "onecentlin.laravel-blade (Laravel Blade Snippets)"
  "github.copilot-chat (GitHub Copilot Chat)"
  "saoudrizwan.claude-dev (Cline)"
  "eamodio.gitlens (GitLens)"
  "sleistner.vscode-fileutils (File Utils)"
  "chouzz.vscode-better-align (Better Align)"
  "esbenp.prettier-vscode (Prettier - Code formatter)"
  "mikestead.dotenv (DotENV)"
  "redhat.vscode-yaml (YAML)"
  "ms-vscode.sublime-keybindings (Sublime Keybindings)"
)

VSCODE_DEFAULT_SELECTED=(  
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

choose_vscode_extensions() {
  local selected_pkgs="$1"
  local gum_default_args=()

  [[ "$selected_pkgs" != *"visual-studio-code"* ]] && return

  for extension in "${VSCODE_DEFAULT_SELECTED[@]+"${VSCODE_DEFAULT_SELECTED[@]}"}"; do
    gum_default_args+=( --selected "$extension" )
  done

  gum choose --no-limit \
    --header="Choose VS Code extensions:" \
    --cursor="> " \
    --cursor-prefix="[ ] " \
    --selected-prefix="[X] " \
    --unselected-prefix="[ ] " \
    "${gum_default_args[@]+"${gum_default_args[@]}"}" \
    "${VSCODE_OPTIONS[@]}"
}

install_vscode_extensions() {
  local selected_pkgs="$1"
  local selected_extensions="$2"
  local code_cmd=""

  [[ "$selected_pkgs" != *"visual-studio-code"* ]] && return
  [[ -z "${selected_extensions// }" ]] && return

  if need_cmd code; then
    code_cmd="code"
  elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    code_cmd="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  else
    echo "VS Code installed but CLI command not found. Skipping extension install."
    return
  fi

  while IFS= read -r extension; do
    [[ -z "${extension// }" ]] && continue
    extension_id=$(sed 's/ (.*//' <<< "$extension")
    echo "❯ $code_cmd --install-extension $extension_id"
    if ! "$code_cmd" --install-extension "$extension_id"; then
      echo "Failed to install VS Code extension: $extension_id"
    fi
  done <<< "$selected_extensions"
}

ensure_xcode_cli_tools
ensure_brew
ensure_gum

gum_default_args=()
for pkg in "${BREW__DEFAULT_SELECTED[@]+"${BREW__DEFAULT_SELECTED[@]}"}"; do
  gum_default_args+=( --selected "$pkg" )
done

selected=$(
  gum choose --no-limit \
    --header="Choose Homebrew packages:" \
    --cursor="> " \
    --cursor-prefix="[ ] " \
    --selected-prefix="[X] " \
    --unselected-prefix="[ ] " \
    "${gum_default_args[@]+"${gum_default_args[@]}"}" \
    "${BREW_OPTIONS[@]}"
)

if [[ -z "${selected// }" ]]; then
  gum style --foreground 244 "No options selected."
  exit 0
fi

selected_vscode_extensions="$(choose_vscode_extensions "$selected")"

summary=""
while IFS= read -r pkg; do
  summary+="• $pkg\n"
  if [[ "$pkg" == "visual-studio-code" && -n "${selected_vscode_extensions// }" ]]; then
    while IFS= read -r ext; do
      [[ -z "${ext// }" ]] && continue
      summary+="  • $ext\n"
    done <<< "$selected_vscode_extensions"
  fi
done <<< "$selected"

gum style --border rounded --padding "0 1" --margin "1 0" \
  "$(printf "%b" "$summary")"

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

install_vscode_extensions "$selected" "$selected_vscode_extensions"

echo "Done."
