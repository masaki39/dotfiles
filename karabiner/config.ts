import {
  rule,
  map,
  writeToProfile,
  toKey,
  toHyper,
  ifDevice,
} from 'karabiner.ts'

// デバイス識別子
const builtIn = { vendor_id: 1452, product_id: 641 }   // Apple Internal Keyboard
const hhkb = { vendor_id: 1278, product_id: 33 }    // HHKB-Hybrid_1

writeToProfile('Default profile', [

  // ── 両キーボード共通 ──────────────────────────────────────

  rule('Left Control').manipulators([
    map('left_control', undefined, 'any')
      .to('left_control')
      .toIfAlone([toKey('japanese_eisuu'), toKey('escape')]),
  ]),

  rule('Space Hyper').manipulators([
    map('spacebar', undefined, 'any')
      .to(toHyper())
      .toIfAlone('spacebar'),
  ]),

  // ── 組み込みキーボードのみ ────────────────────────────────
  rule('Caps Lock → 無効化').condition(ifDevice([builtIn])).manipulators([
    map('caps_lock', undefined, 'any').to('vk_none'),
  ]),

  // ── HHKBのみ ─────────────────────────────────────────────

  rule('Left Cmd → 英数').condition(ifDevice([hhkb])).manipulators([
    map('left_command', undefined, 'any')
      .to('left_command')
      .toIfAlone(toKey('japanese_eisuu')),
  ]),

  rule('Right Cmd → かな').condition(ifDevice([hhkb])).manipulators([
    map('right_command', undefined, 'any')
      .to('right_command')
      .toIfAlone(toKey('japanese_kana')),
  ]),

  rule("; / ' shift反転").condition(ifDevice([hhkb])).manipulators([
    map('semicolon', 'left_shift').to('semicolon'),
    map('semicolon', 'right_shift').to('semicolon'),
    map('semicolon', undefined, 'any').to('semicolon', 'left_shift'),
    map('quote', 'left_shift').to('quote'),
    map('quote', 'right_shift').to('quote'),
    map('quote', undefined, 'any').to('quote', 'left_shift'),
  ]),

])
