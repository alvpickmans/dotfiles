return {
  "toppair/peek.nvim",
  run = 'deno task --quiet build:fast',
  config = function()
    vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
    vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})
  end
}
