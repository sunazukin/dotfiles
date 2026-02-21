# 共通
alias ll='ls -al'
alias python='python3'
alias k='kubectl'
alias awsume='. awsume'
alias cl='clear'
alias pn='claude-pane'

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
export PNPM_HOME="/Users/suzuki/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
