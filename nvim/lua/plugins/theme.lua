return {
	"briones-gabriel/darcula-solid.nvim",
	dependencies = {
		"rktjmp/lush.nvim"
	},
	priority = 1000,
	config = function()
		vim.cmd.colorscheme 'darcula-solid'
		vim.cmd.set 'termguicolors'
		vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
		vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
	end
}
