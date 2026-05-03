import {
  rule,
  map,
  writeToProfile,
  toKey,
  toHyper,
} from 'karabiner.ts'

writeToProfile('Default profile', [
  // Hyper+X: タブ一掃 (新規タブ → 他全タブ閉じる)
  rule('Hyper+X: タブ一掃').manipulators([
    map('x', ['left_shift', 'left_control', 'left_option', 'left_command'])
      .to('t', 'left_command')
      .to('w', ['left_command', 'left_option']),
  ]),

  // Caps Lock → 無効化
  rule('Caps Lock → 無効化').manipulators([
    map('caps_lock', undefined, 'any').to('vk_none'),
  ]),

  // Left Control: 長押し=Ctrl, 単押し=英数+Esc
  rule('Left Control').manipulators([
    map('left_control', undefined, 'any')
      .to('left_control')
      .toIfAlone([toKey('japanese_eisuu'), toKey('escape')]),
  ]),

  // Space: 長押し=Hyper, 単押し=Space
  rule('Space Hyper').manipulators([
    map('spacebar', undefined, 'any')
      .to(toHyper())
      .toIfAlone('spacebar'),
  ]),

  // ESC → ディスプレイスリープ
  rule('ESC → ディスプレイスリープ').manipulators([
    map('escape').to$('pmset displaysleepnow'),
  ]),
])
