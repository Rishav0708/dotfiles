return {
	"numToStr/comment.nvim",
	event = { "BufReadPre", "BufNewFile"},
	config = true --runs require("comment").setup()
}
