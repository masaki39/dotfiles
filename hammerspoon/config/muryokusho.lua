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
		alertDuration = 6,
	},
	hotkeys = {
		addCard = { { "ctrl", "alt", "shift", "cmd" }, "a" },
	},
})
