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
	hotkeys = { showChooser = { { "ctrl", "alt" }, "m" } },
})

spoon.SpoonInstall.repos.imecontrol = {
	url = "https://github.com/masaki39/hammerspoon-ime-control",
	desc = "ImeControl Spoon repository",
	branch = "main",
}
spoon.SpoonInstall:andUse("ImeControl", {
	repo = "imecontrol",
	start = true,
	hotkeys = {
		toggle = { { "shift" }, "f12" },
		debug = { { "shift" }, "f11" },
	},
	config = {
		appRules = {
			["com.apple.Terminal"] = "eng",
			["com.mitchellh.ghostty"] = "eng",
			["com.cmuxterm.app"] = "eng",
			["md.obsidian"] = "eng",
			["net.ankiweb.dtop"] = "eng",
		},
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
							prefix = "C",
						},
						{
							match = { bundleID = "com.cmuxterm.app" },
							prefix = "M",
						},
					},
				},
				navigation = {
					focusBackKey = "tab",
					directionKeys = {
						left = "h",
						down = "j",
						up = "k",
						right = "l",
						upLeft = "y",
						upRight = "u",
						downLeft = "b",
						downRight = "n",
					},
					directHotkeys = {
						modifiers = { "ctrl", "alt", "shift", "cmd" },
						keys = {
							left = "left",
							down = "down",
							up = "up",
							right = "right",
						},
					},
				},
				behavior = {
					centerCursor = true,
				},
			},
			focus_back = {
				hotkey = {
					modifiers = { "option", "shift", "cmd", "ctrl" },
					key = "tab",
				},
				behavior = {
					centerCursor = true,
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
