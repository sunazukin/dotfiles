#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# symlink対象のファイル一覧（dotfiles内の相対パス）
files=(
  .zshrc
  .zprofile
  .gitconfig
  .tmux.conf
  .local/bin/claude-pane
  .config/git/config
  .config/git/ignore
  .config/git/hooks/pre-commit
  .config/gh/config.yml
  .config/gwq/config.toml
  .config/ghostty/config
  .claude/settings.json
  .claude/setting.json
)

for file in "${files[@]}"; do
  src="$DOTFILES/$file"
  dest="$HOME/$file"

  # 親ディレクトリを作成
  mkdir -p "$(dirname "$dest")"

  # 既存ファイルがシンボリックリンクでなければバックアップ
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "Backup: $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  # 既存のシンボリックリンクを削除
  if [[ -L "$dest" ]]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
done

# マシン固有の git 設定を ~/.gitconfig.local に書き込む（dotfiles には含めない）
# hooksPath を絶対パスで設定（~ 展開が環境によって効かないケースへの対策）
git config --file "$HOME/.gitconfig.local" core.hooksPath "$HOME/.config/git/hooks"
echo "Set: ~/.gitconfig.local core.hooksPath -> $HOME/.config/git/hooks"

echo ""
echo "Done! All dotfiles have been linked."
