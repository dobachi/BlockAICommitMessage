#!/bin/bash

# 国際化（i18n）サポートライブラリ
# 日本語と英語のメッセージ切り替えを提供

# 言語設定の取得（環境変数またはシステムロケール）
LANG_CODE="${AI_COMMIT_LANG:-${LANG%%_*}}"

# デフォルト言語の設定
if [[ ! "$LANG_CODE" =~ ^(ja|en)$ ]]; then
    LANG_CODE="en"
fi

# メッセージ取得関数
# 使用法: get_message "key" "english_text" "japanese_text"
get_message() {
    local key=$1
    local en_text=$2
    local ja_text=$3
    
    if [ "$LANG_CODE" = "ja" ] && [ -n "$ja_text" ]; then
        echo "$ja_text"
    else
        echo "$en_text"
    fi
}

# 言語設定の確認関数
get_current_language() {
    echo "$LANG_CODE"
}

# 言語設定の変更関数
set_language() {
    local new_lang=$1
    if [[ "$new_lang" =~ ^(ja|en)$ ]]; then
        export AI_COMMIT_LANG="$new_lang"
        LANG_CODE="$new_lang"
    else
        echo "Error: Unsupported language code: $new_lang" >&2
        return 1
    fi
}