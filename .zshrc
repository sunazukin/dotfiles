# 共通
alias ll='ls -al'
alias python='python3'
alias k='kubectl'
unalias awsume 2>/dev/null
awsume() { source "$(mise which awsume)" "$@"; }
alias cl='clear'
alias pn='claude-pane'
# Tailscale は Mac App 版で CLI が PATH に無いため
alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'

# life-recoding の常駐サーバー（LaunchAgent）を操作する
#   lr status / lr start / lr stop / lr restart / lr log
lr() {
  local label=com.sunazukin.life-recoding
  local target="gui/$(id -u)/$label"
  local plist="$HOME/Library/LaunchAgents/$label.plist"
  case "${1:-status}" in
    start)
      if launchctl print "$target" &>/dev/null; then
        echo "すでに起動しています"
      else
        launchctl bootstrap "gui/$(id -u)" "$plist" && echo "起動しました（画面のビルドに1分ほどかかります）"
      fi ;;
    stop)
      if launchctl print "$target" &>/dev/null; then
        launchctl bootout "$target" || return
        # bootout は非同期なので、登録が消えるまで待つ（直後に start すると「起動済み」と誤判定する）
        local i
        for i in {1..40}; do
          launchctl print "$target" &>/dev/null || break
          sleep 0.5
        done
        echo "停止しました"
      else
        echo "すでに停止しています"
      fi ;;
    restart)
      if launchctl print "$target" &>/dev/null; then
        launchctl kickstart -k "$target" && echo "再起動しました（画面のビルドに1分ほどかかります）"
      else
        lr start
      fi ;;
    status)
      if launchctl print "$target" &>/dev/null; then
        echo "常駐: 有効"
        curl -s -m 3 http://127.0.0.1:3001/api/health && echo || echo "API: 応答なし（起動中かもしれません。lr log で確認）"
      else
        echo "常駐: 停止中（lr start で起動）"
      fi ;;
    log)
      tail -f "$HOME/Library/Logs/life-recoding/api.log" ;;
    *)
      echo "使い方: lr [status|start|stop|restart|log]" ;;
  esac
}

# zsh-completions&autosuggestions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  autoload -Uz compinit && compinit
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# 色設定
autoload -Uz colors
colors

# gitブランチ名表示
if type brew &>/dev/null; then
  source "$(brew --prefix)/opt/zsh-git-prompt/zshrc.sh"
fi

# プロンプトの表示形式
git_prompt() {
  if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = true ]; then
    PROMPT="%F{green}%~%f %F{yellow}git:%f$(git_super_status)"$'\n'"%# "
  else
    PROMPT="%F{green}%~%f"$'\n'"%# "
  fi
}

# 行追加
add_newline() {
  if [[ -z $PS1_NEWLINE_LOGIN ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}

precmd() {
  git_prompt
  add_newline
  # ターミナルのタブ/タイトルにカレントディレクトリを表示（最後の要素のみ）
  print -Pn "\e]0;%1~\a"
}

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"

# ghq/gwqの補助
function ghq-path() {
    ghq list --full-path | fzf
}

function dev() {
    local moveto
    moveto=$(ghq-path)
    cd "${moveto}" || return 1

    # mise のセットアップ
    mise trust
    mise i

    # rename session if in tmux
    if [[ -n ${TMUX} ]]; then
        local repo_name
        repo_name="${moveto##*/}"

        tmux rename-session "${repo_name//./-}"
    fi

    # プロジェクト固有のセットアップスクリプトがあれば実行
    if [[ -x "scripts/setup-worktree.sh" ]]; then
        ./scripts/setup-worktree.sh
    fi
}
source <(gwq completion zsh)


# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
