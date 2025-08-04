# Android UI 解析ツール

[English](README.md) | [中文](README.zh.md) | [Deutsch](README.de.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

---

XMLダンプファイルからAndroid UI階層を分析するための強力なFlutterデスクトップアプリケーションです。このツールは、開発者がUI構造を理解し、レイアウトの問題をデバッグし、UI自動化テスト開発を加速するのに役立ちます。

![アプリスクリーンショット](docs/images/app-screenshot.png)

## 機能

### コア機能
- **🔍 UI階層の可視化**: Android UI構造のインタラクティブツリービュー
- **🔎 高度な検索・フィルタリング**: テキスト、リソースID、クラス名、またはプロパティで要素を検索
- **📊 プロパティ検査**: UI要素の属性と境界の詳細ビュー
- **🖼️ 視覚的プレビュー**: 要素ハイライト付きのスケールされたデバイス画面表示
- **📝 XML表示**: エクスポート機能付きのシンタックスハイライトXML表示
- **📚 履歴管理**: 以前にキャプチャしたUIダンプへのアクセスと管理

### 主な利点
- UI自動化テスト開発の加速
- 複雑なレイアウト階層のデバッグ
- アクセシビリティ構造の理解
- さらなる分析のためのデータエクスポート
- モバイルアプリテストワークフローの効率化

## クイックスタート

### 前提条件
- macOS 10.14以降
- USBデバッグが有効なAndroidデバイス
- ADB（Android Debug Bridge）がインストール済み

### インストール
1. [リリース](https://github.com/your-repo/releases)から最新版をダウンロード
2. 解凍してApplicationsフォルダに移動
3. アプリケーションを起動
4. Androidデバイスを接続して分析を開始！

### 基本的な使用方法
1. **デバイス接続**: USBデバッグが有効なAndroidデバイス
2. **UIキャプチャ**: 「UIキャプチャ」をクリックして現在の画面階層を取得
3. **探索**: ツリービュー、検索、フィルターを使用して要素を検索
4. **検査**: 要素をクリックして詳細プロパティを表示
5. **エクスポート**: 自動化スクリプト用のXMLファイルを保存

## ドキュメント

- **[ユーザーガイド](docs/USER_GUIDE.md)**: 完全なユーザードキュメント
- **[開発者ガイド](docs/DEVELOPER_GUIDE.md)**: 技術実装の詳細
- **[デプロイメントガイド](docs/DEPLOYMENT_GUIDE.md)**: ビルドと配布の手順
- **[テストレポート](docs/TEST_REPORT.md)**: 包括的なテスト検証

## プロジェクト構造

```
lib/
├── main.dart                 # アプリケーションエントリーポイント
├── controllers/              # 状態管理とビジネスロジック
│   ├── ui_analyzer_state.dart
│   ├── search_controller.dart
│   └── filter_controller.dart
├── models/                   # データモデルとエンティティ
│   ├── ui_element.dart
│   ├── android_device.dart
│   └── filter_criteria.dart
├── services/                 # 外部サービス統合
│   ├── adb_service.dart
│   ├── xml_parser.dart
│   ├── file_manager.dart
│   └── user_preferences.dart
├── ui/                       # ユーザーインターフェースコンポーネント
│   ├── panels/              # メインUIパネル
│   ├── widgets/             # 再利用可能なコンポーネント
│   ├── dialogs/             # モーダルダイアログ
│   └── themes/              # テーマ設定
└── utils/                   # ユーティリティ関数とヘルパー

test/                        # 包括的なテストスイート
docs/                        # ドキュメント
```

## 開発

### 前提条件
- Flutter SDK 3.7.2+（FVM経由での管理を推奨）
- Dart SDK 2.19.0+
- macOS開発環境
- Xcode（macOSビルド用）

### セットアップ
```bash
# リポジトリをクローン
git clone <repository-url>
cd android-ui-analyzer

# 依存関係をインストール
fvm flutter pub get

# アプリケーションを実行
fvm flutter run -d macos
```

### 開発コマンド
```bash
# コード解析
fvm flutter analyze

# テスト実行
fvm flutter test

# 統合テスト実行
fvm flutter test test/integration/

# リリースビルド
fvm flutter build macos --release
```

### テスト
プロジェクトには包括的なテストが含まれています：
- **ユニットテスト**: コアビジネスロジックの検証
- **統合テスト**: エンドツーエンド機能の検証
- **ウィジェットテスト**: UIコンポーネントの動作テスト

テストスイートを実行：
```bash
# すべてのテスト
fvm flutter test

# 特定のテストファイル
fvm flutter test test/integration/final_integration_test.dart

# カバレッジ付き
fvm flutter test --coverage
```

## アーキテクチャ

### クリーンアーキテクチャパターン
- **UIレイヤー**: Flutterウィジェットとパネル
- **ビジネスロジック**: コントローラーと状態管理
- **データレイヤー**: サービスとリポジトリ
- **外部**: ADB統合とファイルシステム

### 主要技術
- **Flutter**: クロスプラットフォームUIフレームワーク
- **Provider**: 状態管理
- **XML**: Android UIダンプパース
- **ADB**: Androidデバイス通信
- **Material Design 3**: モダンUIコンポーネント

## 貢献

貢献を歓迎します！貢献ガイドラインをご覧ください：

1. リポジトリをフォーク
2. 機能ブランチを作成
3. テストとともに変更を行う
4. プルリクエストを提出

### コードスタイル
- Dartスタイルガイドに従う
- パブリックAPIのドキュメントを追加
- 新機能のテストを含める
- 意味のあるコミットメッセージを使用

## パフォーマンス

### ベンチマーク
- **XMLパース**: 典型的なUIダンプ < 500ms
- **検索**: < 100ms応答時間
- **メモリ使用量**: 大規模階層に最適化
- **UI応答性**: 60fpsスムーズなインタラクション

### 最適化機能
- 大規模ツリーの遅延読み込み
- パフォーマンスのための仮想スクロール
- 遅延を防ぐためのデバウンス検索
- 効率的なメモリ管理

## セキュリティ

### データ保護
- 機密データの送信なし
- ローカルファイル処理のみ
- 安全な一時ファイル処理
- プライバシー重視の設計

### ベストプラクティス
- 入力検証とサニタイゼーション
- 安全なXMLパース
- 適切なエラーハンドリング
- リソースクリーンアップ

## 互換性

### サポートプラットフォーム
- **プライマリ**: macOS 10.14+
- **Androidデバイス**: API 16+（Android 4.1+）
- **ADBバージョン**: すべての最新バージョン

### テスト済み設定
- 様々なAndroidデバイスメーカー
- 異なる画面サイズと向き
- 複雑なUI階層とレイアウト
- 複数のAndroidバージョン

## トラブルシューティング

### 一般的な問題
- **デバイスが検出されない**: USBデバッグとADBインストールを確認
- **UIキャプチャが失敗**: デバイスがロック解除され、アプリに権限があることを確認
- **パフォーマンスの問題**: フィルターを使用して表示要素を削減

詳細なトラブルシューティングは[ユーザーガイド](docs/USER_GUIDE.md)を参照してください。

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 謝辞

- 素晴らしいフレームワークを提供してくれたFlutterチーム
- UIAutomatorツールを提供してくれたAndroidチーム
- 依存関係を提供してくれたオープンソースコミュニティ
- 貢献者とテスター

## サポート

- **ドキュメント**: docs/ディレクトリを確認
- **問題**: バグレポートにはGitHub Issuesを使用
- **ディスカッション**: 質問にはGitHub Discussionsを使用
- **メール**: [support@example.com](mailto:support@example.com)

---

**Android開発者とテスターのために ❤️で作成** 