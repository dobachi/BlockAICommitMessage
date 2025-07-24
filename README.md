# BlockAICommitMessage

AIが生成したコミットメッセージを検出・ブロックし、人間らしいコミットメッセージの作成を支援するツールです。

## 特徴

- 🔍 **高精度なAI検出**: 署名、パターン、語彙、文体を分析
- 🛡️ **Git Hook統合**: commit時に自動でチェック
- 💡 **作成支援**: インタラクティブモードでメッセージ作成をサポート
- 🌍 **多言語対応**: 日本語・英語対応
- ⚙️ **カスタマイズ可能**: 詳細な設定オプション

## クイックスタート

### 1. クローン
```bash
git clone https://github.com/dobachi/BlockAICommitMessage.git
cd BlockAICommitMessage
```

### 2. インストール

現在のリポジトリにインストール:
```bash
./scripts/setup-hooks.sh install
```

すべてのリポジトリで使用（グローバル）:
```bash
./scripts/setup-hooks.sh install-global
```

### 3. 使用方法

#### AIメッセージの検出
```bash
./scripts/detect-ai-message.sh "Your commit message"
```

#### クリーンなコミット
```bash
# インタラクティブモード
./scripts/clean-commit.sh -i

# 直接コミット
./scripts/clean-commit.sh -m "Fix login bug"
```

## 検出される例

### ❌ ブロックされるメッセージ
- `🤖 Generated with Claude`
- `feat(auth): Implement user authentication system with JWT tokens`
- `This commit updates the documentation to reflect recent changes`
- 詳細な箇条書きを含むメッセージ

### ✅ 許可されるメッセージ
- `Fix login bug`
- `Update README`
- `Add user authentication`
- `Remove deprecated API calls`

## 設定

`config/ai-detection.conf`で動作をカスタマイズできます:

```conf
# 検出レベル: low, medium, high
detection_level=medium

# 絵文字を許可
allow_emoji=false

# インタラクティブモードをデフォルトに
interactive_by_default=true
```

## Git Hooksの動作

### pre-commit
- ステージングエリアの確認
- AIツール設定ファイルの警告

### prepare-commit-msg
- コミットメッセージのAI検出
- 検出時はコミットを中止
- 代替案の提示

## 回避方法（非推奨）

どうしても必要な場合のみ:
```bash
git commit --no-verify -m "Your message"
```

## アンインストール

```bash
# ローカルリポジトリから削除
./scripts/setup-hooks.sh uninstall

# グローバル設定を削除
git config --global --unset core.hooksPath
rm -rf ~/.blockaicommit
```

## トラブルシューティング

### フックが動作しない
```bash
# 状態確認
./scripts/setup-hooks.sh status

# 実行権限の確認
ls -la .git/hooks/
```

### 検出が厳しすぎる/緩すぎる
`config/ai-detection.conf`の`detection_level`を調整してください。

## 開発

詳細な設計は[docs/DESIGN.md](docs/DESIGN.md)を参照してください。

## ライセンス

MIT License

## 貢献

Issue、プルリクエストを歓迎します！

## 作者

dobachi