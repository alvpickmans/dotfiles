" Neovim Plugins configuration

let mapleader = " "

call plug#begin()
"Buffers
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Installing language server
Plug 'neovim/nvim-lspconfig'

" Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Files
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim'
Plug 'preservim/nerdtree'
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'

" C# configuration
Plug 'Omnisharp/omnisharp-vim'
Plug 'dense-analysis/ale'

call plug#end()


let g:Omnisharp_server_studio = 1

" Telescope
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" NerdTree
autocmd VimEnter * NERDTree | wincmd p
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap <leader>tf :NERDTreeFocus<CR>
let g:NERDTreeQuitOnOpen = 1
