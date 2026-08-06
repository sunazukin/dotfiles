# dotfiles

## Setup

```bash
git clone --recursive git@github.com:sunazukin/dotfiles.git
cd dotfiles
./install.sh
```

`--recursive` は private submodule（`private/`）も取得する。clone 済みで未取得なら `git submodule update --init --recursive`。private submodule には SSH 鍵とアクセス権が必要で、取得できない環境では該当リンク（`~/.claude/scheduled-tasks`）はスキップされる。

## Managed files

| File | Target |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.zprofile` | `~/.zprofile` |
| `.gitconfig` | `~/.gitconfig` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.local/bin/claude-pane` | `~/.local/bin/claude-pane` |
| `.config/git/config` | `~/.config/git/config` |
| `.config/git/ignore` | `~/.config/git/ignore` |
| `.config/gh/config.yml` | `~/.config/gh/config.yml` |
| `.config/gwq/config.toml` | `~/.config/gwq/config.toml` |
| `.config/ghostty/config` | `~/.config/ghostty/config` |
| `.claude/settings.json` | `~/.claude/settings.json` |
| `.claude/setting.json` | `~/.claude/setting.json` |
| `.claude/skills/next-pr` | `~/.claude/skills/next-pr` |
| `private/.claude/scheduled-tasks` | `~/.claude/scheduled-tasks` |

`.claude/skills/` はスキル単位でリンクする（ディレクトリごとリンクすると、dotfiles で管理していないスキルが隠れてしまうため）。スキルを追加したら `install.sh` の `files` とこの表の両方に足す。

`private/` は private submodule（[dotfiles-private](https://github.com/sunazukin/dotfiles-private)）。認証情報は置かず、公開できない設定のみを管理する。
