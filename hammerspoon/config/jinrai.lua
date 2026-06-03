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
					cycleLeft = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "left",
						},
					},
					cycleHorizontalCenter = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "c",
						},
					},
					cycleRight = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "right",
						},
					},
					cycleTop = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "up",
						},
					},
					cycleVerticalCenter = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "v",
						},
					},
					cycleBottom = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "down",
						},
					},
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
							full = "A",
							halfLeft = "H",
							halfRight = "L",
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
