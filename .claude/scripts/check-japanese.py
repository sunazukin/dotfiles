#!/usr/bin/env python3
"""Stop フック: ターンの最後の返答に英語だけの文が混ざっていたら止める。

検査するのは、最後のツール呼び出しより後に書いた assistant テキスト（＝最後の報告）だけ。
ツールの合間の一行ナレーションは作業ログ扱いで英語でもよい（2026-10-07 本人指示）。
"""
import json
import re
import sys

KANA = re.compile(r"[぀-ヿ]")
ASCII_WORD = re.compile(r"[A-Za-z]{2,}")
CODE_BLOCK = re.compile(r"```.*?```", re.S)
INLINE_CODE = re.compile(r"`[^`]*`")
URL = re.compile(r"https?://\S+|\[[^\]]*\]\([^)]*\)")


def is_real_user_message(entry):
    if entry.get("type") != "user" or entry.get("isMeta"):
        return False
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, str):
        return bool(content.strip())
    if isinstance(content, list):
        return any(isinstance(c, dict) and c.get("type") == "text" for c in content)
    return False


def looks_english(text):
    body = URL.sub(" ", INLINE_CODE.sub(" ", CODE_BLOCK.sub(" ", text)))
    words = ASCII_WORD.findall(body)
    if len(words) < 3:
        return False
    # カタカナ語が1つ混ざっただけの英文（「Registered 3 slots in AIタスク」）も拾うため、
    # かなの有無ではなく英字との比率で見る
    kana = len(KANA.findall(body))
    letters = sum(len(w) for w in words)
    return kana < 3 or kana / (kana + letters) < 0.2


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    if data.get("stop_hook_active"):
        return 0
    path = data.get("transcript_path")
    if not path:
        return 0
    try:
        with open(path, encoding="utf-8") as f:
            entries = [json.loads(line) for line in f if line.strip()]
    except Exception:
        return 0

    start = 0
    for i, e in enumerate(entries):
        if is_real_user_message(e):
            start = i + 1

    # 最後のツール呼び出しより後のテキストだけを残す（ツールを呼ぶたびに捨てる）
    final_texts = []
    for e in entries[start:]:
        if e.get("type") != "assistant":
            continue
        content = (e.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for c in content:
            if not isinstance(c, dict):
                continue
            if c.get("type") == "tool_use":
                final_texts = []
            elif c.get("type") == "text":
                final_texts.append(c.get("text") or "")

    offenders = [
        t.strip().replace("\n", " ")[:80] for t in final_texts if looks_english(t)
    ]

    if not offenders:
        return 0
    listed = "\n".join(f"- {o}" for o in offenders[:5])
    print(json.dumps({
        "decision": "block",
        "reason": (
            "英語で書いた文が混ざっています（ユーザー向けの出力は常に日本語）。\n"
            f"{listed}\n"
            "上の内容を日本語で言い直してください。"
        ),
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
