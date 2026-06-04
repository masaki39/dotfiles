hs.loadSpoon("SpoonInstall")

-- HHKB keymap image overlay (toggle with hyper+/)
local hhkbCanvas = nil
hs.hotkey.bind({ "alt", "shift", "cmd", "ctrl" }, "h", function()
	if hhkbCanvas then
		hhkbCanvas:delete()
		hhkbCanvas = nil
		return
	end
	local img = hs.image.imageFromPath(os.getenv("HOME") .. "/.hammerspoon/help.svg")
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
		showChooser = { { "ctrl", "alt" }, "m" },
		maximizeAll = { { "ctrl", "alt" }, "a" },
		unhideAll = { { "ctrl", "alt" }, "z" },
		tileAll = { { "ctrl", "alt" }, "x" },
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
require("config.jinrai")

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

-- Muryokusho: word → translation → Anki card
spoon.SpoonInstall.repos.muryokusho = {
	url = "https://github.com/masaki39/muryokusho",
	desc = "Muryokusho Spoon repository",
	branch = "main",
}
spoon.SpoonInstall:andUse("Muryokusho", {
	repo = "muryokusho",
	start = true,
	config = {
		ankiDeck = "Default",
		ankiModelName = "基本",
		ankiFrontField = "表面",
		ankiBackField = "裏面",
		translationMethod = "google",
		language = "ja",
		allowDuplicate = false,
		alertDuration = 6, -- seconds (click or any key also dismisses)
	},
	hotkeys = {
		addCard = { { "ctrl", "alt", "shift", "cmd" }, "a" },
	},
})
