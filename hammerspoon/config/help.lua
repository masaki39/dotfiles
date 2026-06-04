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
