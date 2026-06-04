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
