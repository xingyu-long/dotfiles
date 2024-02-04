if exists('g:vscode')
    " VSCode extension
    let g:mapleader = " "

    " search file
    nnoremap <silent> <leader>ff :call VSCodeNotify('workbench.action.quickOpen')<CR>
    xnoremap <silent> <leader>ff :call VSCodeNotify('workbench.action.quickOpen')<CR>

    " Better Navigation
    nnoremap <silent> <C-j> :call VSCodeNotify('workbench.action.navigateDown')<CR>
    xnoremap <silent> <C-j> :call VSCodeNotify('workbench.action.navigateDown')<CR>
    nnoremap <silent> <C-k> :call VSCodeNotify('workbench.action.navigateUp')<CR>
    xnoremap <silent> <C-k> :call VSCodeNotify('workbench.action.navigateUp')<CR>
    nnoremap <silent> <C-h> :call VSCodeNotify('workbench.action.navigateLeft')<CR>
    xnoremap <silent> <C-h> :call VSCodeNotify('workbench.action.navigateLeft')<CR>
    nnoremap <silent> <C-l> :call VSCodeNotify('workbench.action.navigateRight')<CR>
    xnoremap <silent> <C-l> :call VSCodeNotify('workbench.action.navigateRight')<CR>

    " window / splits
    nnoremap <silent> <leader>sv :call VSCodeNotify('workbench.action.splitEditor')<CR>
    xnoremap <silent> <leader>sv :call VSCodeNotify('workbench.action.splitEditor')<CR>
    nnoremap <silent> <leader>sh :call VSCodeNotify('workbench.action.splitEditorDown')<CR>
    xnoremap <silent> <leader>sh :call VSCodeNotify('workbench.action.splitEditorDown')<CR>

    " buffer
    nnoremap <silent> <S-h> :call VSCodeNotify('workbench.action.previousEditorInGroup')<CR>
    xnoremap <silent> <S-h> :call VSCodeNotify('workbench.action.previousEditorInGroup')<CR>
    nnoremap <silent> <S-l> :call VSCodeNotify('workbench.action.nextEditorInGroup') <CR>
    xnoremap <silent> <S-l> :call VSCodeNotify('workbench.action.nextEditorInGroup') <CR>

    " file tree
    nnoremap <silent> <leader>e :call VSCodeNotify('workbench.action.toggleSidebarVisibility')<CR>
    xnoremap <silent> <leader>e :call VSCodeNotify('workbench.action.toggleSidebarVisibility')<CR>

    " Bind C-/ to vscode commentary since calling from vscode produces double comments due to multiple cursors
    xnoremap <silent> <leader>/ :call VSCodeNotify('editor.action.commentLine')<CR>
    nnoremap <silent> <leader>/ :call VSCodeNotify('editor.action.commentLine')<CR>


else
    " ordinary Neovim
endif
