import {
  rule,
  layer,
  map,
  withMapper,
  writeToProfile,
  toKey,
  toHyper,
} from 'karabiner.ts'

writeToProfile('Default profile', [
  // 英数レイヤー: hjkl矢印 + 数字キー
  layer('japanese_eisuu', 'eisuu_layer')
    .manipulators([
      map('h', undefined, 'any').to('left_arrow'),
      map('j', undefined, 'any').to('down_arrow'),
      map('k', undefined, 'any').to('up_arrow'),
      map('l', undefined, 'any').to('right_arrow'),
      withMapper({
        right_command: '0' as const,
        period: '1' as const,
        slash: '2' as const,
        international1: '3' as const,
        semicolon: '4' as const,
        quote: '5' as const,
        backslash: '6' as const,
        p: '7' as const,
        open_bracket: '8' as const,
        close_bracket: '9' as const,
      })((from, to) => map(from, undefined, 'any').to(to)),
    ]),

  // Hyper+X: タブ一掃 (新規タブ → 他全タブ閉じる)
  rule('Hyper+X: タブ一掃').manipulators([
    map('x', ['left_shift', 'left_control', 'left_option', 'left_command'])
      .to('t', 'left_command')
      .to('w', ['left_command', 'left_option']),
  ]),

  // Caps Lock → Left Control
  rule('Caps Lock → Left Control').manipulators([
    map('caps_lock', undefined, 'any').to('left_control'),
  ]),

  // Hyperキー: Left Control (長押し=Hyper, 単押し=英数+Esc)
  rule('Hyperキー').manipulators([
    map('left_control', undefined, 'any')
      .to(toHyper())
      .toIfAlone([toKey('japanese_eisuu'), toKey('escape')]),
  ]),

  // ESC → ディスプレイスリープ
  rule('ESC → ディスプレイスリープ').manipulators([
    map('escape').to$('pmset displaysleepnow'),
  ]),
])
