return {
	keybind = "ctrl+alt+1",
	description = "Obsidian --> Ghostty --> Google Chrome",
	windows = {
		{ app = "Google Chrome", screen = 0, x = 0, y = 0, w = 1, h = 1 },
		{ app = "Ghostty", screen = 1, x = 0.667, y = 0, w = 0.333, h = 1 },
		{ app = "Obsidian", screen = 1, x = 0, y = 0, w = 0.667, h = 1, focus = true },
	},
}
