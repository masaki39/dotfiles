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
