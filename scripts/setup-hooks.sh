#!/bin/bash

# BlockAICommitMessage セットアップスクリプト
# Git hooksのインストール/アンインストール/状態確認

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# アクション
ACTION=${1:-status}

# Git リポジトリチェック
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}エラー: Gitリポジトリではありません${NC}"
        exit 1
    fi
}

# インストール関数
install_hooks() {
    echo -e "${BLUE}=== BlockAICommitMessage フックのインストール ===${NC}\n"
    
    check_git_repo
    
    local git_dir=$(git rev-parse --git-dir)
    local hooks_dir="$git_dir/hooks"
    local installed=0
    local skipped=0
    
    # フックファイルのリスト
    local hooks=("pre-commit" "prepare-commit-msg")
    
    for hook in "${hooks[@]}"; do
        local source_file="$PROJECT_ROOT/hooks/$hook"
        local target_file="$hooks_dir/$hook"
        
        if [ ! -f "$source_file" ]; then
            echo -e "${YELLOW}警告: ソースファイルが見つかりません: $source_file${NC}"
            continue
        fi
        
        # 既存のフックがある場合
        if [ -f "$target_file" ]; then
            echo -e "${YELLOW}既存のフックが見つかりました: $hook${NC}"
            echo "上書きしますか？ (y/N): "
            read -r response
            
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}スキップ: $hook${NC}"
                skipped=$((skipped + 1))
                continue
            fi
            
            # バックアップを作成
            cp "$target_file" "$target_file.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}バックアップを作成しました${NC}"
        fi
        
        # フックをコピー
        cp "$source_file" "$target_file"
        chmod +x "$target_file"
        echo -e "${GREEN}✓ インストール: $hook${NC}"
        installed=$((installed + 1))
    done
    
    echo -e "\n${GREEN}完了: ${installed}個のフックをインストール、${skipped}個をスキップ${NC}"
    
    # グローバルインストールの提案
    echo -e "\n${BLUE}ヒント:${NC} すべてのリポジトリで使用するには、以下を実行してください:"
    echo -e "${YELLOW}$0 install-global${NC}"
}

# グローバルインストール関数
install_global() {
    echo -e "${BLUE}=== グローバルインストール ===${NC}\n"
    
    local install_dir="$HOME/.blockaicommit"
    
    # インストールディレクトリの作成
    mkdir -p "$install_dir"
    mkdir -p "$install_dir/scripts"
    mkdir -p "$install_dir/hooks"
    mkdir -p "$install_dir/config"
    
    # ファイルのコピー
    echo "ファイルをコピー中..."
    cp -r "$PROJECT_ROOT/scripts/"* "$install_dir/scripts/"
    cp -r "$PROJECT_ROOT/hooks/"* "$install_dir/hooks/"
    
    # 設定ファイルのテンプレートを作成
    if [ ! -f "$install_dir/config/ai-detection.conf" ]; then
        cat > "$install_dir/config/ai-detection.conf" << 'EOF'
# BlockAICommitMessage 設定ファイル
detection_level=medium
allow_emoji=false
check_grammar=true
check_vocabulary=true
max_message_length=72
min_message_length=10
suggest_templates=true
interactive_by_default=false
auto_cleanup=true
log_detections=true
log_file=~/.ai-commit-block.log
EOF
    fi
    
    # グローバルGitフックの設定
    git config --global core.hooksPath "$install_dir/hooks"
    
    echo -e "${GREEN}✓ グローバルインストール完了${NC}"
    echo -e "\n${YELLOW}注意:${NC} 個別のリポジトリでフックを無効にするには:"
    echo "git config --local core.hooksPath .git/hooks"
}

# アンインストール関数
uninstall_hooks() {
    echo -e "${BLUE}=== フックのアンインストール ===${NC}\n"
    
    check_git_repo
    
    local git_dir=$(git rev-parse --git-dir)
    local hooks_dir="$git_dir/hooks"
    local removed=0
    
    local hooks=("pre-commit" "prepare-commit-msg")
    
    for hook in "${hooks[@]}"; do
        local hook_file="$hooks_dir/$hook"
        
        if [ -f "$hook_file" ]; then
            # BlockAICommitMessageのフックか確認
            if grep -q "BlockAICommitMessage" "$hook_file" 2>/dev/null || \
               grep -q "AIコミットメッセージ" "$hook_file" 2>/dev/null; then
                rm "$hook_file"
                echo -e "${GREEN}✓ 削除: $hook${NC}"
                removed=$((removed + 1))
                
                # バックアップがあれば復元を提案
                local backup=$(ls -t "$hook_file.backup."* 2>/dev/null | head -1)
                if [ -n "$backup" ]; then
                    echo "バックアップを復元しますか？ ($backup) (y/N): "
                    read -r response
                    if [[ "$response" =~ ^[Yy]$ ]]; then
                        mv "$backup" "$hook_file"
                        echo -e "${GREEN}バックアップを復元しました${NC}"
                    fi
                fi
            else
                echo -e "${YELLOW}スキップ: $hook (BlockAICommitMessageのフックではありません)${NC}"
            fi
        fi
    done
    
    echo -e "\n${GREEN}完了: ${removed}個のフックを削除${NC}"
}

# 状態確認関数
check_status() {
    echo -e "${BLUE}=== BlockAICommitMessage 状態確認 ===${NC}\n"
    
    check_git_repo
    
    local git_dir=$(git rev-parse --git-dir)
    local hooks_dir="$git_dir/hooks"
    
    echo -e "${YELLOW}ローカルフック:${NC}"
    local hooks=("pre-commit" "prepare-commit-msg")
    
    for hook in "${hooks[@]}"; do
        local hook_file="$hooks_dir/$hook"
        
        if [ -f "$hook_file" ]; then
            if grep -q "BlockAICommitMessage" "$hook_file" 2>/dev/null || \
               grep -q "AIコミットメッセージ" "$hook_file" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $hook: BlockAICommitMessage"
            else
                echo -e "  ${YELLOW}○${NC} $hook: 他のフック"
            fi
        else
            echo -e "  ${RED}✗${NC} $hook: 未インストール"
        fi
    done
    
    # グローバル設定の確認
    echo -e "\n${YELLOW}グローバル設定:${NC}"
    local global_hooks=$(git config --global core.hooksPath)
    if [ -n "$global_hooks" ]; then
        echo -e "  フックパス: $global_hooks"
        if [[ "$global_hooks" == *"blockaicommit"* ]]; then
            echo -e "  ${GREEN}✓ BlockAICommitMessageがグローバルに設定されています${NC}"
        fi
    else
        echo -e "  ${YELLOW}グローバルフックは設定されていません${NC}"
    fi
    
    # 検出スクリプトの確認
    echo -e "\n${YELLOW}スクリプト:${NC}"
    if [ -f "$PROJECT_ROOT/scripts/detect-ai-message.sh" ]; then
        echo -e "  ${GREEN}✓${NC} detect-ai-message.sh"
    else
        echo -e "  ${RED}✗${NC} detect-ai-message.sh"
    fi
    
    if [ -f "$PROJECT_ROOT/scripts/clean-commit.sh" ]; then
        echo -e "  ${GREEN}✓${NC} clean-commit.sh"
    else
        echo -e "  ${RED}✗${NC} clean-commit.sh"
    fi
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [command]"
    echo ""
    echo "コマンド:"
    echo "  install         現在のリポジトリにフックをインストール"
    echo "  install-global  すべてのリポジトリ用にグローバルインストール"
    echo "  uninstall       現在のリポジトリからフックを削除"
    echo "  status          インストール状態を確認（デフォルト）"
    echo "  help            このヘルプを表示"
}

# メイン処理
case "$ACTION" in
    install)
        install_hooks
        ;;
    install-global)
        install_global
        ;;
    uninstall)
        uninstall_hooks
        ;;
    status)
        check_status
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo -e "${RED}エラー: 不明なコマンド: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac