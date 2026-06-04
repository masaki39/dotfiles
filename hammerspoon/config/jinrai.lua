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
						key = "tab",
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
					},
				},
			},
			focus_back = {
				hotkey = {
					modifiers = { "option", "shift", "cmd", "ctrl" },
					key = "tab",
				},
			},
			window_mover = {
				commands = {
					moveToNextDisplay = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "space",
						},
					},
					moveToActiveDisplayFreeArea = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "tab",
						},
					},
					maximizeWindow = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "return",
						},
					},
					cycleLeft = { hotkey = { modifiers = { "option", "ctrl" }, key = "h" } },
					cycleRight = { hotkey = { modifiers = { "option", "ctrl" }, key = "l" } },
					cycleTop = { hotkey = { modifiers = { "option", "ctrl" }, key = "p" } },
					cycleBottom = { hotkey = { modifiers = { "option", "ctrl" }, key = "n" } },
					cycleHorizontalCenter = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "c",
						},
					},
					cycleVerticalCenter = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "v",
						},
					},
					quarterTopLeft = { hotkey = { modifiers = { "option", "ctrl" }, key = "u" } },
					quarterTopRight = { hotkey = { modifiers = { "option", "ctrl" }, key = "i" } },
					quarterBottomLeft = { hotkey = { modifiers = { "option", "ctrl" }, key = "j" } },
					quarterBottomRight = { hotkey = { modifiers = { "option", "ctrl" }, key = "k" } },
					sixthTopLeft = { hotkey = { modifiers = { "option", "ctrl" }, key = "e" } },
					sixthTopCenter = { hotkey = { modifiers = { "option", "ctrl" }, key = "r" } },
					sixthTopRight = { hotkey = { modifiers = { "option", "ctrl" }, key = "t" } },
					sixthBottomLeft = { hotkey = { modifiers = { "option", "ctrl" }, key = "d" } },
					sixthBottomCenter = { hotkey = { modifiers = { "option", "ctrl" }, key = "f" } },
					sixthBottomRight = { hotkey = { modifiers = { "option", "ctrl" }, key = "g" } },
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
						},
					},
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
