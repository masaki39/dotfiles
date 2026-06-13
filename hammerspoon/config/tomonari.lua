spoon.SpoonInstall.repos.tomonari = {
	url = "https://github.com/masaki39/tomonari",
	desc = "Tomonari Spoon repository",
	branch = "main",
}
spoon.SpoonInstall:andUse("Tomonari", {
	repo = "tomonari",
	config = { menubarIcon = "⌨️", menubarHidden = true },
	hotkeys = {
		showMenu = { { "ctrl", "alt", "shift", "cmd" }, "t" },
	},
	start = true,
})
