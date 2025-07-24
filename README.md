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

#### インストール方法の選択

3つのインストール方法から選択できます：

| 方法 | オプション | 依存性 | 推奨用途 |
|------|-----------|--------|----------|
| **コピー方式** | (デフォルト) | BlockAICommitMessageに依存 | 一時的な使用 |
| **シンボリックリンク** | `--symlink` | BlockAICommitMessageに強く依存 | 開発中のプロジェクト |
| **スタンドアロン** | `--standalone` | 依存なし（独立動作） | 本番/長期プロジェクト |

#### 特定のリポジトリにインストール

```bash
# デフォルト（コピー方式）
./scripts/setup-hooks.sh install ~/MyProject

# シンボリックリンク方式（更新が自動反映）
./scripts/setup-hooks.sh install --symlink ~/MyProject

# スタンドアロン方式（完全に独立、BlockAICommitMessageを削除しても動作）
./scripts/setup-hooks.sh install --standalone ~/MyProject
```

#### すべてのリポジトリで使用（グローバル）
```bash
# ホームディレクトリに完全コピーしてグローバル設定
./scripts/setup-hooks.sh install-global
```

#### 注意事項

- **コピー/シンボリックリンク方式**: BlockAICommitMessageのリポジトリを削除・移動すると動作しなくなります
- **スタンドアロン方式**: すべての機能をフックに埋め込むため、ファイルサイズが大きくなりますが、完全に独立して動作します
- **グローバルインストール**: `~/.blockaicommit/`にファイルをコピーするため、常に独立して動作します

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