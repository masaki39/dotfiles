hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall:andUse("ReloadConfiguration", { start = true })

-- Ryoiki: window layout manager
spoon.SpoonInstall.repos.ryoiki = {
	url = "https://github.com/masaki39/ryoiki",
	desc = "Ryoiki Spoon repository",
	branch = "main",
}

spoon.SpoonInstall:andUse("Ryoiki", {
	repo = "ryoiki",
	start = true,
	config = { centerCursor = true },
	hotkeys = { showChooser = { { "ctrl", "alt" }, "m" } },
})

-- Hanten
spoon.SpoonInstall.repos.hanten = {
	url = "https://github.com/masaki39/hanten",
	desc = "Hanten Spoon repository",
	branch = "main",
}
spoon.SpoonInstall:andUse("Hanten", {
	repo = "hanten",
	start = true,
	hotkeys = {
		toggle = { { "shift" }, "f12" },
		debug = { { "shift" }, "f11" },
	},
	config = {
		defaultIME = "eng",
	},
})

-- Jinrai
spoon.SpoonInstall.repos.jinrai = {
	url = "https://github.com/tadashi-aikawa/jinrai",
	desc = "JINRAI Spoon repository",
	branch = "spoons",
}

spoon.SpoonInstall:andUse("Jinrai", {
	repo = "jinrai",
	fn = function(jinrai)
		jinrai:setup({
			focus_border = {},
			window_hints = {
				hotkey = {
					modifiers = { "alt", "shift", "cmd", "ctrl" },
					key = "j",
				},
				hint = {
					prefixOverrides = {
						{
							match = { bundleID = "com.google.Chrome" },
							prefix = "B",
						},
					},
				},
				navigation = {
					focusBack = {
						key = "a",
					},
					direction = {
						hints = {
							keys = {
								left = "h",
								down = "j",
								up = "k",
								right = "l",
							},
						},
						direct = {
							modifiers = { "ctrl", "alt", "shift", "cmd" },
							keys = {
								left = "left",
								down = "down",
								up = "up",
								right = "right",
							},
						},
					},
				},
			},
			focus_back = {
				hotkey = {
					modifiers = { "option", "shift", "cmd", "ctrl" },
					key = "a",
				},
				stateSync = {
					interval = 0.15,
					targetApps = { "com.mitchellh.ghostty" },
					historyScope = "application",
				},
			},
		})
	end,
})
