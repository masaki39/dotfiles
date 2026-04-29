return {
	keybind = "ctrl+alt+q",
	description = "Obsidian --> Ghostty --> Google Chrome",
	windows = {
		{ app = "com.google.Chrome", screen = 0, x = 0, y = 0, w = 1, h = 1 },
		{ app = "com.mitchellh.ghostty", screen = 1, x = 0.667, y = 0, w = 0.333, h = 1 },
		{ app = "md.obsidian", screen = 1, x = 0, y = 0, w = 0.667, h = 1, focus = true },
	},
}
