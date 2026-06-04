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
      .toIfAlone([toKey('japanese_eisuu'), toKey('escape')])
      .parameters({ 'basic.to_if_alone_timeout_milliseconds': 200 }),
  ]),

  rule('Emacs Keybindings').manipulators([
    map('h', 'control').to('delete_or_backspace'),
    map('p', 'control').to('up_arrow'),
    map('n', 'control').to('down_arrow'),
    map('f', 'control').to('right_arrow'),
    map('b', 'control').to('left_arrow'),
  ]),

  rule('Tab Navigation').manipulators([
    map('h', ['command', 'option']).to('left_arrow', ['command', 'option']),
    map('l', ['command', 'option']).to('right_arrow', ['command', 'option']),
  ]),

  rule('Semicolon Hyper').manipulators([
    map('semicolon', undefined, 'any')
      .to(toHyper())
      .toIfAlone('semicolon')
      .parameters({ 'basic.to_if_alone_timeout_milliseconds': 200 }),
  ]),

  // ── 組み込みキーボードのみ ────────────────────────────────
  rule('Caps Lock → 無効化').condition(ifDevice([builtIn])).manipulators([
    map('caps_lock', undefined, 'any').to('vk_none'),
  ]),

  // ── HHKBのみ ─────────────────────────────────────────────

  rule('Left Cmd → 英数').condition(ifDevice([hhkb])).manipulators([
    map('left_command', undefined, 'any')
      .to('left_command')
      .toIfAlone(toKey('japanese_eisuu'))
      .parameters({ 'basic.to_if_alone_timeout_milliseconds': 200 }),
  ]),

  rule('Right Cmd → かな').condition(ifDevice([hhkb])).manipulators([
    map('right_command', undefined, 'any')
      .to('right_command')
      .toIfAlone(toKey('japanese_kana'))
      .parameters({ 'basic.to_if_alone_timeout_milliseconds': 200 }),
  ]),

])
