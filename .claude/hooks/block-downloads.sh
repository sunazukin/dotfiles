#!/bin/bash
# ダウンロードフォルダの中で Claude Code を使わせない（UserPromptSubmit フック）。
# Web ページが黙って置いた AGENTS.md / CLAUDE.md を読み込ませないための守り。
cwd=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd", ""))')
case "$cwd" in
  */Downloads|*/Downloads/*)
    echo "ダウンロードフォルダでは使えません。作業するプロジェクトのフォルダで起動し直してください。" >&2
    exit 2
    ;;
esac
exit 0
