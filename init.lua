require("duckdb"):setup()
require("full-border"):setup()
require("bunny"):setup({
    hops = {
        { key = "h", path = "~", desc = "Home directory" },
        { key = "c", path = "~/.config", desc = "Config files" },
        { key = "v", path = "~/dev", desc = "dev" },
        { key = "d", path = "~/Downloads", desc = "Downloads" },
        { key = "o", path = "~/Documents/masaki39-core", desc = "Obsidian" },
        { key = "p", path = "~/pCloud Drive", desc = "pCloud Drive" }, 
        { key = "w", path = "~/pCloud Drive/Work", desc = "Work" }, 
        { key = "x", path = "~/pCloud Drive/Work/20230400-大学院", desc = "大学院" }, 
    },
    desc_strategy = "path", -- If desc isn't present, use "path" or "filename", default is "path"
    ephemeral = true, -- Enable ephemeral hops, default is true
    tabs = true, -- Enable tab hops, default is true
    notify = false, -- Notify after hopping, default is false
    fuzzy_cmd = "fzf", -- Fuzzy searching command, default is "fzf"
})
