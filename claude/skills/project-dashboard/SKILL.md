---
name: project-dashboard
description: プロジェクトの目標・タスク状態・次にやること・決定事項を dashboard/status.toml 1ファイルで管理し、HTMLダッシュボードとセッション開始時の要約を生成する。ユーザーがダッシュボードの導入・更新・表示を頼んだとき、またはカレントプロジェクトに dashboard/status.toml があり、タスク完了・実験の開始/完了・方針決定などの作業の区切りに来たときに使う。
---

# project-dashboard

`dashboard/status.toml` を唯一の情報源として、次の2つを生成する。

- `dashboard/index.html`：人が見るダッシュボード（git管理外）
- テキスト要約：グローバルの SessionStart フックがセッション開始時に会話へ入れる

スクリプトは標準ライブラリのみで動き、Python 3.11 以上（tomllib）が必要。システムの python3 は古いので、必ず uv で実行する。

```bash
S=~/.claude/skills/project-dashboard/scripts/build_dashboard.py
uv run --no-project --python '>=3.11' $S            # HTML生成
uv run --no-project --python '>=3.11' $S --open     # 生成してブラウザで開く
uv run --no-project --python '>=3.11' $S --summary  # 要約のみ
```

カレントディレクトリをプロジェクトルートとして扱う（`$CLAUDE_PROJECT_DIR` があればそちら、`--root DIR` で明示も可）。

## 導入（新しいプロジェクト）

1. `templates/status.toml` を `dashboard/status.toml` にコピーし、ユーザーと話して目標・次にやること・マイルストーンを埋める。曖昧な点は AskUserQuestion で確認する
2. `.gitignore` に `dashboard/index.html` を追加する
3. プロジェクトの CLAUDE.md に、次の短い運用ルールを追記する
   > 進捗管理: 目標・タスク状態・次のアクション・決定事項は `dashboard/status.toml` が唯一の管理ファイル。作業の区切りごとに更新し、project-dashboard スキルで `dashboard/index.html` を再生成する。
4. HTMLを生成し、`--open` で開いて確認してもらう

プロジェクト側にフックの設定は要らない。`~/.claude/settings.json` の SessionStart フックが、`dashboard/status.toml` のあるプロジェクトでだけ要約を出す。

## 運用（作業の区切りごと）

- タスクの `status` を更新する：`todo` / `doing` / `blocked` / `decide`（ユーザー判断待ち）/ `done`
- `next_actions` は上から実行順。終わったものは消し、次のものを先頭に置く。新しいセッションがこれだけ読んで再開できるように、具体的に書く（実行中のジョブなら進み具合・ログの場所・再開方法まで）
- 方針を決めたら `[[decisions]]` の先頭に日付つきで追加する
- 長い経緯や知見は status.toml に溜めず、プロジェクトの別文書（README・RESEARCH.md 等）に書く。不採用になった案の記録も残さない（経緯は git 履歴に任せる）
- 更新したら HTML を再生成する。status.toml のコミットはユーザーの指示に従う

## status.toml のスキーマ

必須は `[goal].title` だけで、ほかはすべて任意。無いセクションは表示しない。

| キー | 内容 |
|---|---|
| `[goal]` | `title`、`short_title`（HTMLの<title>）、`target` と `target_label`（期限・提出先など）、`summary`、`glossary`（用語の配列）、`next_actions`（配列） |
| `[[milestones]]` | `name` と `tasks`（`{title, status, note}` の配列） |
| `[[results]]` | KPIタイル。`label`、`value`、`note` |
| `[[experiments]]` | 結果JSONの自動集計（下記） |
| `[[decisions]]` | `date` と `text` |

### experiments（結果JSONの自動集計）

`dir` 内のJSONを読み、`metric`（ドット区切りのキー。例 `overall.mre_mm`）の値を集める。

- `glob` を指定しない場合：`fold*_size*.json` をファイル名の `size<N>` ごとに平均±SDにし、学習曲線のグラフと表を出す。差が2以内のサイズは1つにまとめる（fold ごとに上限が 148/149 のようにずれる場合のため）
- `glob` を指定した場合：fold 別の結果として、表と平均±SDを出す
- `expected_jobs` との比較で進み具合（done/expected）を表示する。`dir` の親ディレクトリが無い（外付けディスク未接続など）ときは、エラーにせず「未接続」と表示する
- `glob` は数えたいファイルだけに当てはまるようにする。たとえば `fold*_size1*.json` は size120 にも当たり、件数が予定を超える
