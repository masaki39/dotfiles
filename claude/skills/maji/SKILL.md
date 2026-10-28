---
name: maji
description: herdrで調査・作業・レビューのエージェントを別タブに立て、指揮役として意思決定に専念するワークフロー。ユーザーがmajiを指定したとき、または大きな作業・別リポジトリの作業で複数エージェントの指揮を頼んだときに使う。小さな作業では使わない。
---

# maji

自分は指揮役。ユーザーと話し、決め、検証する。作業は自分でしない。

```
目的確認(AUQ) ─ 小規模? ─yes→ 単独で実行(majiを終了)
      │no
      ▼
確認レベルを選択(事前のみ/節目ごと/逐次)
      ▼
調査(並列可) → 方針決定 ──→ 作業(1体) → レビュー(別エージェント)
                  ▲                            │
                  └───── NG(指摘を渡す) ←──────┘
                                               │OK
                                               ▼
                                     git diffで検証 → 報告 → 作ったタブを閉じる
```

- 作業への指示は自己完結させる: 目的 / 完了条件 / 触ってよい範囲 / 決定済みの方針
- レビュー合格基準: 完了条件を満たす + テスト・ビルドが通る。作業者の自己報告は根拠にしない
- 作業エージェントは1体。並列にするのは調査とレビューだけ
- 選ばれた確認レベルを超えてユーザーに確認しない。方針を変える判断が必要なときだけ例外
- herdrの操作は `herdr --skill` を読んでから。配下は別タブ(`herdr tab create`)に起動する
- 状態報告: 節目ごとに `herdr workspace report-metadata $HERDR_WORKSPACE_ID --source maji --token phase=<p> --token loop=<NG回数> --token worker=<pane> --token reviewer=<pane> --token investigators=<pane>,<pane> --ttl-ms 86400000`
  (phase: investigate / decide / work / review / verify / report / done。値は80文字まで。終了時は `--clear-token` で消す)
- ビューア: `herdr pane split --current --direction down --no-focus` → `herdr pane run <pane> "uv run --script ~/.claude/skills/maji/viewer.py"` (`--once` でテキスト出力)
