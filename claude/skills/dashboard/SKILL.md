---
name: dashboard
description: プロジェクトの目標・タスク状態・次にやること・決定事項を dashboard/status.toml 1ファイルで管理し、HTMLダッシュボードとセッション開始時の要約を生成する。ユーザーがダッシュボードの導入・更新・表示を頼んだとき、またはカレントプロジェクトに dashboard/status.toml があり、タスク完了・実験の開始/完了・方針決定などの作業の区切りに来たときに使う。
---

# dashboard

`dashboard/status.toml` を唯一の情報源として、次の2つを生成する。

- `dashboard/index.html`：人が見るダッシュボード（git管理外）
- テキスト要約（`--summary`）：セッション開始時に自動で会話へ入る

スクリプトは標準ライブラリのみで動くが Python 3.11+（tomllib）が必要なので、uv で実行する。

```bash
S=~/.claude/skills/dashboard/scripts/build_dashboard.py
uv run --no-config --no-project --python '>=3.11' $S            # HTML生成
uv run --no-config --no-project --python '>=3.11' $S --open     # 生成してブラウザで開く
uv run --no-config --no-project --python '>=3.11' $S --summary  # 要約のみ
```

プロジェクトルートは `--root DIR` → `$CLAUDE_PROJECT_DIR` → カレントディレクトリの順に決まる。

## 導入（新しいプロジェクト）

1. `templates/status.toml` を `dashboard/status.toml` にコピーし、ユーザーと話して目標・次にやること・マイルストーンを埋める。曖昧な点は AskUserQuestion で確認する
2. `.gitignore` に `dashboard/index.html` を追加する
3. プロジェクトの CLAUDE.md に、次の短い運用ルールを追記する
   > 進捗管理: 目標・タスク状態・次のアクション・決定事項は `dashboard/status.toml` が唯一の管理ファイル。作業の区切りごとに更新し、dashboard スキルで `dashboard/index.html` を再生成する。
4. HTMLを生成し、`--open` で開いて確認してもらう

プロジェクト側にフックの設定は要らない。`~/.claude/settings.json` の SessionStart フックが、`dashboard/status.toml` のあるプロジェクトでだけ要約を出す。status.toml に誤りがあると、要約の代わりに `[dashboard] status.toml の読み込みに失敗: …` が出るので、それを直す。

## 運用（作業の区切りごと）

- タスクの `status` を更新する：`todo` / `doing` / `blocked` / `decide`（ユーザー判断待ち）/ `done`
- `next_actions` は上から実行順。終わったものは消し、次のものを先頭に置く。新しいセッションがこれだけ読んで再開できるように、具体的に書く（実行中のジョブなら進み具合・ログの場所・再開方法まで）
- 方針を決めたら `[[decisions]]` の先頭に日付つきで追加する
- 長い経緯や知見は status.toml に溜めず、プロジェクトの別文書（README・RESEARCH.md 等）に書く。不採用になった案の記録も残さない（経緯は git 履歴に任せる）
- 更新したら HTML を再生成する。status.toml のコミットはユーザーの指示に従う

## status.toml のスキーマ

必須は `[goal].title` だけ。無いセクションは表示しない。

**`[goal]`**
- `title`：目標（1行）
- `short_title`：HTMLの `<title>`
- `target` / `target_label`：期限・提出先などとその見出し
- `summary`：目標の補足（1〜2文）
- `glossary`：新しいセッションが知るべき用語の配列
- `next_actions`：次にやることの配列（上から実行順）

**`[[milestones]]`**：`name` と `tasks`（`{title, status, note}` の配列）

**`[[results]]`**：KPIタイル。`label`・`value`・`note`

**`[[decisions]]`**：`date` と `text`（新しいものを上に）

**`[[experiments]]`**：結果JSONの自動集計（次節）

### experiments（結果JSONの自動集計）

| キー | 必須 | 内容 |
|---|---|---|
| `name` | ○ | 表示名 |
| `dir` | ○ | 結果JSONのディレクトリ。相対パスはプロジェクトルート基準、`~` 可 |
| `expected_jobs` | ○ | 予定の件数 |
| `metric` | ○ | JSON内のドット区切りキー（例 `overall.score`） |
| `metric_label` | | 指標の表示名（既定は `metric`） |
| `x_label` | | 学習曲線の横軸名（既定「サイズ」。例「学習症例数」） |
| `group_label` | | 繰り返しの単位名（既定「fold」） |
| `glob` | | 対象ファイルのパターン。指定すると fold 別の結果になる |
| `note` | | 補足 |

- `glob` 無し：`fold*_size*.json` をファイル名の `size<N>` ごとに平均±SDにし、学習曲線と表を出す。上限サイズが fold ごとに少しずれる場合のため、差が2以内で fold が重ならないサイズは1つにまとめる
- `glob` 有り：ファイル名の `fold<N>` ごとの表と平均±SDを出す
- 進み具合は「値を取れたファイル数 / `expected_jobs`」。予定を超えると警告色になる。書きかけ・指標なしのJSONは数えず、件数を別に表示する
- `dir` の親ディレクトリが無い（外付けディスク未接続など）ときは、エラーにせず「未接続」と表示する
- `glob` は数えたいファイルだけに当てはまるようにする。たとえば `fold*_size1*.json` は size120 にも当たる
