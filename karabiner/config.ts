import {
  rule,
  map,
  writeToProfile,
  toKey,
  toHyper,
} from 'karabiner.ts'

writeToProfile('Default profile', [

  rule('Emacs Keybindings').manipulators([
    map('h', 'control').to('delete_or_backspace'),
    map('p', 'control').to('up_arrow'),
    map('n', 'control').to('down_arrow'),
    map('f', 'control').to('right_arrow'),
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

  rule('Caps Lock to Control').manipulators([
    map('caps_lock', undefined, 'any').to('left_control'),
  ]),

  rule('Escape to Eisuu').manipulators([
    map('escape').to([toKey('escape'), toKey('japanese_eisuu')]),
  ]),

])
