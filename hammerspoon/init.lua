hs.loadSpoon("SpoonInstall")

-- HHKB keymap image overlay (toggle with hyper+/)
local hhkbCanvas = nil
hs.hotkey.bind({ "alt", "shift", "cmd", "ctrl" }, "h", function()
	if hhkbCanvas then
		hhkbCanvas:delete()
		hhkbCanvas = nil
		return
	end
	local img = hs.image.imageFromPath(os.getenv("HOME") .. "/.hammerspoon/help.jpg")
	if not img then
		hs.alert("image load failed")
		return
	end
	local screen = hs.screen.mainScreen()
	local f = screen:frame()
	local imgSize = img:size()
	local scale = math.min(f.w / imgSize.w, f.h / imgSize.h, 1)
	local w = imgSize.w * scale
	local h = imgSize.h * scale
	local x = f.x + (f.w - w) / 2
	local y = f.y + (f.h - h) / 2
	hhkbCanvas = hs.canvas.new({ x = x, y = y, w = w, h = h })
	hhkbCanvas:appendElements({
		type = "image",
		image = img,
		imageScaling = "scaleToFit",
		frame = { x = 0, y = 0, w = w, h = h },
	})
	hhkbCanvas:level(hs.canvas.windowLevels.overlay)
	hhkbCanvas:clickActivating(false)
	hhkbCanvas:show()
end)

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
	hotkeys = {
		showChooser  = { { "ctrl", "alt" }, "m" },
		saveLayout   = { { "ctrl", "alt" }, "s" },
		deleteLayout = { { "ctrl", "alt" }, "d" },
		maximizeAll  = { { "ctrl", "alt" }, "a" },
		unhideAll    = { { "ctrl", "alt" }, "z" },
		tileAll      = { { "ctrl", "alt" }, "x" },
	},
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
		})
	end,
})

-- Tomonari: keyboard typing sound
spoon.SpoonInstall.repos.tomonari = {
	url = "https://github.com/masaki39/tomonari",
	desc = "Tomonari Spoon repository",
	branch = "main",
}
spoon.SpoonInstall:andUse("Tomonari", {
	repo = "tomonari",
	start = true,
})
