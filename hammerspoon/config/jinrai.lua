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
					moveToSelectedArea = {
						hotkey = {
							modifiers = { "option", "shift", "cmd", "ctrl" },
							key = "k",
						},
					},
					maximizeWindow = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = "return",
						},
					},
					minimizeWindow = {
						hotkey = {
							modifiers = { "option", "ctrl" },
							key = nil,
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
					defaultScreen = "7F72F02E-3AEE-9A31-0857-D6964E3302DB",
					screens = {
						-- name: DELL P2723DE
						-- id: 2
						-- frame: x=-1120.0, y=-1440.0, w=2560.0, h=1440.0
						["7F72F02E-3AEE-9A31-0857-D6964E3302DB"] = {
							full = "A",
							halfLeft = "H",
							halfBottom = "J",
							halfTop = "K",
							halfRight = "L",
							halfHorizontalCenter = "C",
							halfVerticalCenter = "V",
							thirdLeft = "S",
							thirdHorizontalCenter = "D",
							thirdRight = "F",
							thirdTop = "P",
							thirdVerticalCenter = "I",
							thirdBottom = "N",
							twoThirdsHorizontalCenter = "R",
							twoThirdsVerticalCenter = "T",
							quarterLeft = "1",
							quarterHorizontalLeftCenter = "2",
							quarterHorizontalRightCenter = "3",
							quarterRight = "4",
							quarterTop = "5",
							quarterVerticalTopCenter = "6",
							quarterVerticalBottomCenter = "7",
							quarterBottom = "8",
							["1920x1080Center"] = "M",
						},
					},
				},
			},
		})
	end,
})
