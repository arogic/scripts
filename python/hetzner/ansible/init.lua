vim.opt.guicursor = ''
vim.cmd('let &t_SI = ""')
vim.cmd('let &t_EI = ""')
vim.cmd('let &t_SR = ""')

vim.api.nvim_create_autocmd('VimEnter', { pattern = '*', command = 'redraw!' })
vim.api.nvim_create_autocmd('BufEnter', { pattern = '*', command = 'redraw!' })

vim.opt.title = false
vim.opt.titleold = ''

vim.opt.termguicolors = true
vim.opt.clipboard = 'unnamedplus'
vim.g.termfeatures = { osc52 = false }

vim.cmd.colorscheme('catppuccin')
