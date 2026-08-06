#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# private submodule を取得（認証が必要なため、失敗しても install 全体は止めない）
git -C "$DOTFILES" submodule update --init --recursive \
  || echo "Warn: private submodule の取得に失敗しました（未取得のまま続行します）"

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
  .claude/skills/next-pr
)

# src を dest に symlink する（ファイル・ディレクトリ共通）
link() {
  local src="$1" dest="$2"

  # 親ディレクトリを作成
  mkdir -p "$(dirname "$dest")"

  # 既存の実体（シンボリックリンクでない）はバックアップ
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
}

# ホーム鏡像のファイル群
for file in "${files[@]}"; do
  link "$DOTFILES/$file" "$HOME/$file"
done

# private submodule 配下（dotfiles 内のパスと $HOME 側のパスが異なるため個別指定）
if [[ -e "$DOTFILES/private/.claude/scheduled-tasks" ]]; then
  link "$DOTFILES/private/.claude/scheduled-tasks" "$HOME/.claude/scheduled-tasks"
else
  echo "Skip: private/.claude/scheduled-tasks が未取得のためリンクしません"
fi

# Ghostty 背景画像のセットアップ
# ~/Downloads/cat-image.jpg が存在し、まだ移行されていない場合にコピーする
GHOSTTY_BG="$HOME/.config/ghostty/bg.jpg"
DOWNLOADS_BG="$HOME/Downloads/cat-image.jpg"
if [[ -f "$DOWNLOADS_BG" && ! -f "$GHOSTTY_BG" ]]; then
  cp "$DOWNLOADS_BG" "$GHOSTTY_BG"
  echo "Copied: $DOWNLOADS_BG -> $GHOSTTY_BG"
elif [[ ! -f "$GHOSTTY_BG" ]]; then
  echo "Note: Ghostty 背景画像が見つかりません。~/.config/ghostty/bg.jpg に画像を配置してください。"
fi

# マシン固有の git 設定を ~/.gitconfig.local に書き込む（dotfiles には含めない）
# hooksPath を絶対パスで設定（~ 展開が環境によって効かないケースへの対策）
git config --file "$HOME/.gitconfig.local" core.hooksPath "$HOME/.config/git/hooks"
echo "Set: ~/.gitconfig.local core.hooksPath -> $HOME/.config/git/hooks"

echo ""
echo "Done! All dotfiles have been linked."
