return {
	"rose-pine/neovim",
	name = "rose-pine",
	priority = 1000,
	config = function()
		vim.cmd("colorscheme rose-pine-moon")
		-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })         -- Set background of main editor to transparent
		-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })     -- Set background of floating windows to transparent
	end,
}
