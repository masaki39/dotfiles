spoon.SpoonInstall.repos.jinrai = {
	url = "https://github.com/tadashi-aikawa/jinrai",
	desc = "JINRAI Spoon repository",
	branch = "spoons",
}

local hyper = { "option", "shift", "cmd", "ctrl" }
local mods = { "option", "ctrl" }

spoon.SpoonInstall:andUse("Jinrai", {
	repo = "jinrai",
	fn = function(jinrai)
		jinrai:setup({
			focus_border = {},
			window_hints = {
				hotkey = { modifiers = hyper, key = "j" },
				hint = {
					prefixOverrides = {
						{ match = { bundleID = "com.google.Chrome" }, prefix = "B" },
					},
				},
				navigation = {
					focusBack = { key = "tab" },
					direction = {
						hints = {
							keys = {
								left = "h",
								down = "j",
								up = "k",
								right = "l",
							},
						},
					},
					windowMover = { moveToSelectedArea = { key = "space" } },
				},
			},
			focus_back = { hotkey = { modifiers = hyper, key = "tab" } },
			window_mover = {
				commands = {
					moveToNextDisplay = { hotkey = { modifiers = mods, key = "space" } },
					moveToActiveDisplayFreeArea = { hotkey = { modifiers = mods, key = "tab" } },
					maximizeWindow = { hotkey = { modifiers = mods, key = "return" } },
					cycleLeft = { hotkey = { modifiers = mods, key = "h" } },
					cycleRight = { hotkey = { modifiers = mods, key = "l" } },
					cycleTop = { hotkey = { modifiers = mods, key = "p" } },
					cycleBottom = { hotkey = { modifiers = mods, key = "n" } },
					cycleHorizontalCenter = { hotkey = { modifiers = mods, key = "c" } },
					cycleVerticalCenter = { hotkey = { modifiers = mods, key = "v" } },
					quarterTopLeft = { hotkey = { modifiers = mods, key = "u" } },
					quarterTopRight = { hotkey = { modifiers = mods, key = "i" } },
					quarterBottomLeft = { hotkey = { modifiers = mods, key = "j" } },
					quarterBottomRight = { hotkey = { modifiers = mods, key = "k" } },
					sixthTopLeft = { hotkey = { modifiers = mods, key = "e" } },
					sixthTopCenter = { hotkey = { modifiers = mods, key = "r" } },
					sixthTopRight = { hotkey = { modifiers = mods, key = "t" } },
					sixthBottomLeft = { hotkey = { modifiers = mods, key = "d" } },
					sixthBottomCenter = { hotkey = { modifiers = mods, key = "f" } },
					sixthBottomRight = { hotkey = { modifiers = mods, key = "g" } },
				},
				behavior = {
					cursor = {
						afterMove = true,
					},
				},
				selectedArea = {
					defaultScreen = "37D8832A-2D66-02CA-B9F7-8F30A301B230",
					screens = {
						-- name: Built-in Retina Display
						["37D8832A-2D66-02CA-B9F7-8F30A301B230"] = {
							full = "a",
							halfLeft = "h",
							halfRight = "l",
							quarterTopLeft = "u",
							quarterTopRight = "i",
							quarterBottomLeft = "j",
							quarterBottomRight = "k",
							sixthTopLeft = "e",
							sixthTopCenter = "r",
							sixthTopRight = "t",
							sixthBottomLeft = "d",
							sixthBottomCenter = "f",
							sixthBottomRight = "g",
						},
						["7F72F02E-3AEE-9A31-0857-D6964E3302DB"] = {
							full = ";a",
							halfLeft = ";h",
							halfRight = ";l",
							quarterTopLeft = ";u",
							quarterTopRight = ";i",
							quarterBottomLeft = ";j",
							quarterBottomRight = ";k",
							sixthTopLeft = ";e",
							sixthTopCenter = ";r",
							sixthTopRight = ";t",
							sixthBottomLeft = ";d",
							sixthBottomCenter = ";f",
							sixthBottomRight = ";g",
							twoThirdsLeft = ";y",
							twoThirdsRight = ";o",
						},
					},
					actions = { closeWindow = "x" },
					windowHints = { key = "space" },
				},
			},
			jinrai_mode = {
				triggers = {
					windowHints = {
						key = "m", -- Key to start JinraiMode while Window Hints is shown
					},
				},
			},
		})
	end,
})
