#!/bin/bash

# クリーンコミット支援ツール
# AIメッセージを検出・除去し、人間らしいコミットメッセージ作成を支援

# カラー出力用の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 引数処理
INTERACTIVE=0
MESSAGE=""
AUTO_STAGE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interactive)
            INTERACTIVE=1
            shift
            ;;
        -a|--all)
            AUTO_STAGE=1
            shift
            ;;
        -m|--message)
            MESSAGE="$2"
            shift 2
            ;;
        -h|--help)
            echo -e "${CYAN}クリーンコミット支援ツール${NC}"
            echo ""
            echo "使用方法:"
            echo "  $0 -m \"コミットメッセージ\"     # 直接コミット"
            echo "  $0 -i                         # インタラクティブモード"
            echo "  $0 -i -a                      # 全ファイルを自動ステージング"
            echo ""
            echo "オプション:"
            echo "  -m, --message    コミットメッセージを指定"
            echo "  -i, --interactive インタラクティブモードで実行"
            echo "  -a, --all        全ての変更を自動的にステージング"
            echo "  -h, --help       このヘルプを表示"
            exit 0
            ;;
        *)
            MESSAGE="$1"
            shift
            ;;
    esac
done

# git状態チェック関数
check_git_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}エラー: Gitリポジトリではありません${NC}"
        exit 1
    fi

    # 変更があるかチェック
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${YELLOW}コミットする変更がありません${NC}"
        exit 0
    fi
}

# AIメッセージ検出関数
detect_ai_message() {
    local msg="$1"
    if [ -f "$SCRIPT_DIR/detect-ai-message.sh" ]; then
        if ! "$SCRIPT_DIR/detect-ai-message.sh" "$msg" > /dev/null 2>&1; then
            return 1  # AI detected
        fi
    fi
    return 0  # Clean
}

# コミットメッセージテンプレート提案
suggest_template() {
    echo -e "\n${CYAN}=== コミットメッセージテンプレート ===${NC}"
    echo -e "${YELLOW}以下から選択するか、独自のメッセージを入力してください:${NC}\n"
    
    # 変更されたファイルから推測
    local changed_files=$(git diff --cached --name-only 2>/dev/null || git diff --name-only)
    local file_count=$(echo "$changed_files" | wc -l)
    local first_file=$(echo "$changed_files" | head -1)
    
    echo "1) Update $first_file"
    echo "2) Fix bug in $first_file"
    echo "3) Add new feature"
    echo "4) Refactor code"
    echo "5) Update documentation"
    echo "6) Fix typo"
    echo "7) Improve performance"
    echo "8) Clean up code"
    echo "9) 独自のメッセージを入力"
    echo ""
}

# インタラクティブモード
interactive_commit() {
    echo -e "${CYAN}=== クリーンコミット インタラクティブモード ===${NC}\n"
    
    # 現在の状態を表示
    echo -e "${YELLOW}現在の変更:${NC}"
    git status --short
    echo ""
    
    # 自動ステージング
    if [ $AUTO_STAGE -eq 1 ]; then
        echo -e "${YELLOW}全ての変更をステージング中...${NC}"
        git add -A
        echo -e "${GREEN}✓ ステージング完了${NC}\n"
    fi
    
    # ステージングされたファイルがあるかチェック
    if git diff --cached --quiet; then
        echo -e "${YELLOW}ステージングされた変更がありません。${NC}"
        echo -e "変更をステージングしてください: ${CYAN}git add <ファイル>${NC}"
        exit 1
    fi
    
    # テンプレート提案
    suggest_template
    
    # 選択を取得
    read -p "選択 (1-9): " choice
    
    case $choice in
        1)
            local first_file=$(git diff --cached --name-only | head -1)
            MESSAGE="Update $first_file"
            ;;
        2)
            local first_file=$(git diff --cached --name-only | head -1)
            MESSAGE="Fix bug in $first_file"
            ;;
        3) MESSAGE="Add new feature" ;;
        4) MESSAGE="Refactor code" ;;
        5) MESSAGE="Update documentation" ;;
        6) MESSAGE="Fix typo" ;;
        7) MESSAGE="Improve performance" ;;
        8) MESSAGE="Clean up code" ;;
        9)
            echo -e "\n${CYAN}コミットメッセージを入力してください:${NC}"
            read -p "> " MESSAGE
            ;;
        *)
            echo -e "${RED}無効な選択です${NC}"
            exit 1
            ;;
    esac
    
    # 詳細を追加するか確認
    echo -e "\n${YELLOW}詳細を追加しますか? (y/N):${NC}"
    read -p "> " add_detail
    
    if [[ $add_detail =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}詳細を入力してください (空行で終了):${NC}"
        DETAIL=""
        while IFS= read -r line; do
            [ -z "$line" ] && break
            DETAIL="${DETAIL}\n${line}"
        done
        if [ -n "$DETAIL" ]; then
            MESSAGE="${MESSAGE}${DETAIL}"
        fi
    fi
}

# メイン処理
check_git_status

# インタラクティブモード
if [ $INTERACTIVE -eq 1 ]; then
    interactive_commit
fi

# メッセージが指定されていない場合
if [ -z "$MESSAGE" ]; then
    echo -e "${RED}エラー: コミットメッセージが指定されていません${NC}"
    echo "使用方法: $0 -m \"メッセージ\" または $0 -i"
    exit 1
fi

# AIメッセージ検出
echo -e "\n${YELLOW}コミットメッセージをチェック中...${NC}"
if ! detect_ai_message "$MESSAGE"; then
    echo -e "${RED}⚠️  AIメッセージが検出されました${NC}"
    echo -e "${YELLOW}メッセージを修正してください${NC}"
    
    # AIパターンを除去する簡単な処理
    CLEANED_MESSAGE=$(echo "$MESSAGE" | sed -E '
        s/🤖[^[:space:]]*//g
        s/Co-Authored-By:.*//g
        s/\[AI\]//g
        s/\[Bot\]//g
        s/Generated with.*//g
        s/AI-generated.*//g
    ' | sed '/^[[:space:]]*$/d' | head -1)
    
    if [ -n "$CLEANED_MESSAGE" ]; then
        echo -e "\n${CYAN}クリーンアップ案:${NC}"
        echo "$CLEANED_MESSAGE"
        echo -e "\n${YELLOW}この案を使用しますか? (y/N):${NC}"
        read -p "> " use_cleaned
        
        if [[ $use_cleaned =~ ^[Yy]$ ]]; then
            MESSAGE="$CLEANED_MESSAGE"
        else
            echo -e "${CYAN}新しいメッセージを入力してください:${NC}"
            read -p "> " MESSAGE
        fi
    else
        echo -e "${CYAN}新しいメッセージを入力してください:${NC}"
        read -p "> " MESSAGE
    fi
    
    # 再チェック
    if ! detect_ai_message "$MESSAGE"; then
        echo -e "${RED}まだAIパターンが含まれています。処理を中止します。${NC}"
        exit 1
    fi
fi

# コミット実行
echo -e "\n${YELLOW}コミットを実行中...${NC}"
echo -e "${CYAN}メッセージ:${NC} $MESSAGE\n"

if git commit -m "$MESSAGE"; then
    echo -e "\n${GREEN}✅ コミット成功!${NC}"
    git log -1 --oneline --color=always
else
    echo -e "\n${RED}❌ コミット失敗${NC}"
    exit 1
fi