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
BLOCKAICOMMIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 引数処理
ACTION=${1:-status}
INSTALL_METHOD="copy"  # デフォルト: copy, symlink, standalone

# 引数を解析
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --standalone)
            INSTALL_METHOD="standalone"
            shift
            ;;
        --symlink)
            INSTALL_METHOD="symlink"
            shift
            ;;
        --copy)
            INSTALL_METHOD="copy"
            shift
            ;;
        *)
            TARGET_REPO="$1"
            shift
            ;;
    esac
done

# ターゲットリポジトリが指定されていない場合はカレントディレクトリ
TARGET_REPO=${TARGET_REPO:-$(pwd)}

# ターゲットリポジトリの検証
if [ "$ACTION" != "install-global" ] && [ "$ACTION" != "help" ]; then
    # install, uninstall, statusの場合はターゲットリポジトリを確認
    if [ ! -d "$TARGET_REPO/.git" ]; then
        echo -e "${RED}エラー: $TARGET_REPO はGitリポジトリではありません${NC}"
        echo -e "${YELLOW}使用方法: $0 $ACTION [オプション] [対象リポジトリのパス]${NC}"
        exit 1
    fi
fi

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
    
    # ターゲットリポジトリに移動
    cd "$TARGET_REPO" || exit 1
    
    check_git_repo
    
    local git_dir=$(git rev-parse --git-dir)
    local hooks_dir="$git_dir/hooks"
    local installed=0
    local skipped=0
    
    # フックファイルのリスト
    local hooks=("pre-commit" "prepare-commit-msg")
    
    for hook in "${hooks[@]}"; do
        local source_file="$BLOCKAICOMMIT_ROOT/hooks/$hook"
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
        
        # インストール方法を選択
        if [ "$INSTALL_METHOD" = "standalone" ]; then
            # スタンドアロンインストール（依存関係を含めてコピー）
            echo -e "${YELLOW}スタンドアロンインストール中...${NC}"
            
            # 一時ファイルを作成
            local temp_hook=$(mktemp)
            
            # フックファイルのヘッダー
            cat > "$temp_hook" << 'EOF'
#!/bin/bash
# BlockAICommitMessage - Standalone Hook
# このフックは独立して動作します

EOF
            
            # 必要なライブラリを埋め込む
            if [[ "$hook" == "prepare-commit-msg" ]]; then
                echo "# 埋め込みAIパターン定義" >> "$temp_hook"
                cat "$BLOCKAICOMMIT_ROOT/scripts/lib/ai-patterns.sh" >> "$temp_hook"
                echo "" >> "$temp_hook"
                echo "# 埋め込み検出ロジック" >> "$temp_hook"
                # detect-ai-message.shの主要部分を埋め込む
                sed -n '/^# AI署名パターン/,/^# 結果出力/p' "$BLOCKAICOMMIT_ROOT/scripts/detect-ai-message.sh" >> "$temp_hook"
            fi
            
            # 元のフックロジックを追加（外部依存を削除）
            sed 's|"\$DETECT_SCRIPT"|bash -c "$(declare -f detect_ai_message); detect_ai_message"|g' "$source_file" >> "$temp_hook"
            
            mv "$temp_hook" "$target_file"
        else
            # 通常のインストール（シンボリックリンクまたはコピー）
            if [ "$INSTALL_METHOD" = "symlink" ]; then
                ln -sf "$source_file" "$target_file"
                echo -e "${GREEN}✓ シンボリックリンク作成: $hook${NC}"
            else
                cp "$source_file" "$target_file"
                echo -e "${GREEN}✓ コピー: $hook${NC}"
            fi
        fi
        
        chmod +x "$target_file"
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
    cp -r "$BLOCKAICOMMIT_ROOT/scripts/"* "$install_dir/scripts/"
    cp -r "$BLOCKAICOMMIT_ROOT/hooks/"* "$install_dir/hooks/"
    
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
    
    # ターゲットリポジトリに移動
    cd "$TARGET_REPO" || exit 1
    
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
    
    # ターゲットリポジトリに移動
    cd "$TARGET_REPO" || exit 1
    
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
    if [ -f "$BLOCKAICOMMIT_ROOT/scripts/detect-ai-message.sh" ]; then
        echo -e "  ${GREEN}✓${NC} detect-ai-message.sh (ソース: $BLOCKAICOMMIT_ROOT)"
    elif [ -f "$HOME/.blockaicommit/scripts/detect-ai-message.sh" ]; then
        echo -e "  ${GREEN}✓${NC} detect-ai-message.sh (グローバルインストール)"
    else
        echo -e "  ${RED}✗${NC} detect-ai-message.sh"
    fi
    
    if [ -f "$BLOCKAICOMMIT_ROOT/scripts/clean-commit.sh" ]; then
        echo -e "  ${GREEN}✓${NC} clean-commit.sh (ソース: $BLOCKAICOMMIT_ROOT)"
    elif [ -f "$HOME/.blockaicommit/scripts/clean-commit.sh" ]; then
        echo -e "  ${GREEN}✓${NC} clean-commit.sh (グローバルインストール)"
    else
        echo -e "  ${RED}✗${NC} clean-commit.sh"
    fi
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [command] [オプション] [対象リポジトリパス]"
    echo ""
    echo "コマンド:"
    echo "  install          指定リポジトリにフックをインストール"
    echo "  install-global   すべてのリポジトリ用にグローバルインストール"
    echo "  uninstall        指定リポジトリからフックを削除"
    echo "  status           インストール状態を確認"
    echo "  help             このヘルプを表示"
    echo ""
    echo "インストールオプション:"
    echo "  --copy           フックをコピー（デフォルト）"
    echo "  --symlink        シンボリックリンクを作成"
    echo "  --standalone     依存関係を埋め込んだ独立版を作成"
    echo ""
    echo "例:"
    echo "  # デフォルト（コピー方式）"
    echo "  $0 install ~/MyProject"
    echo ""
    echo "  # シンボリックリンク（開発中のプロジェクトに推奨）"
    echo "  $0 install --symlink ~/MyProject"
    echo ""
    echo "  # スタンドアロン（本番環境に推奨）"
    echo "  $0 install --standalone ~/MyProject"
    echo ""
    echo "  # グローバルインストール"
    echo "  $0 install-global"
    echo ""
    echo "注意:"
    echo "  - copy/symlink: BlockAICommitMessageの削除・移動で動作しなくなります"
    echo "  - standalone: 完全に独立して動作しますが、更新は反映されません"
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