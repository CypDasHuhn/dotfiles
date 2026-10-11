return {
  'techwizrd/render-latex.nvim',
  ft = 'markdown',
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('render-latex-conceal', { clear = true }),
      pattern = 'markdown',
      callback = function()
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = 'nc'
      end,
    })
  end,
  opts = {
    tmux = { install_cleanup_hooks = true },
  },
}
