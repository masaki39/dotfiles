hs.loadSpoon("Jinrai")

local hyper = { "option", "shift", "cmd", "ctrl" }
local mods = { "option", "ctrl" }

local internalUUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230"
local prefix = ";"

-- selectedAreaキーマップ設計方針:
-- - vim方向キーの一貫性を最優先: h=左, l=右, k=上, j=下, i=水平中央, ,=垂直中央
-- - 単一文字: よく使うポジション(halves/quarters2x2/sixths/twoThirds水平)
-- - 2文字シーケンス: 数字プレフィックス(3=thirds, 2=twoThirds, 4=4等分)
-- - 将来の追加・変更はこの方針に従うこと
local base = {
	freeArea = "f",
	-- Full
	full = "a",
	-- Halves
	halfLeft = "h",
	halfRight = "l",
	halfHorizontalCenter = "i",
	halfTop = "k",
	halfBottom = "j",
	halfVerticalCenter = ",",
	-- Quarters (2x2)
	quarterTopLeft = "u",
	quarterTopRight = "o",
	quarterBottomLeft = "m",
	quarterBottomRight = ".",
	-- Sixths (2x3)
	sixthTopLeft = "6u",
	sixthTopCenter = "6i",
	sixthTopRight = "6o",
	sixthBottomLeft = "6m",
	sixthBottomCenter = "6,",
	sixthBottomRight = "6.",
	-- Two-thirds horizontal (2: prefix)
	twoThirdsLeft = "2h",
	twoThirdsHorizontalCenter = "2i",
	twoThirdsRight = "2l",
	-- Thirds (3: prefix)
	thirdLeft = "3h",
	thirdHorizontalCenter = "3i",
	thirdRight = "3l",
	thirdTop = "3k",
	thirdVerticalCenter = "3,",
	thirdBottom = "3j",
	-- Two-thirds vertical (2: prefix)
	twoThirdsTop = "2k",
	twoThirdsVerticalCenter = "2,",
	twoThirdsBottom = "2j",
	-- Quarter strips horizontal (4: prefix, h/u/i/l = outer-left to outer-right)
	quarterLeft = "4h",
	quarterHorizontalLeftCenter = "4u",
	quarterHorizontalRightCenter = "4i",
	quarterRight = "4l",
	-- Quarter strips vertical (4: prefix, k/,/m/j = outer-top to outer-bottom)
	quarterTop = "4k",
	quarterVerticalTopCenter = "4,",
	quarterVerticalBottomCenter = "4m",
	quarterBottom = "4j",
}

local externalUUID
for _, s in ipairs(hs.screen.allScreens()) do
	local uuid = s:getUUID()
	if uuid ~= internalUUID then
		externalUUID = uuid
		break
	end
end

local screensConfig
if externalUUID then
	-- 外付けあり: 外付け=全アクション, 内蔵=単一文字のみ+プレフィックス
	local prefixed = {}
	for k, v in pairs(base) do
		if #v == 1 then
			prefixed[k] = prefix .. v
		end
	end
	screensConfig = { [internalUUID] = prefixed, [externalUUID] = base }
else
	screensConfig = { [internalUUID] = base }
end

spoon.Jinrai:setup({
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
			moveToSelectedAreaInJinraiMode = { hotkey = { modifiers = hyper, key = "m" } },
		},
		behavior = {
			cursor = { afterMove = true },
		},
		selectedArea = {
			defaultScreen = internalUUID,
			screens = screensConfig,
			actions = { closeWindow = "x" },
			windowHints = { key = "space" },
		},
	},
	jinrai_mode = {
		triggers = {
			windowHints = {
				key = "m",
			},
		},
		combo = {
			character = { enabled = true }, -- 迅雷ちゃんのミニキャラ画像を表示
			text = { enabled = true }, -- 『● Combo』のテキストを表示
		},
	},
})
