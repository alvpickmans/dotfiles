return {
  -- UI for debugging
  'rcarriga/nvim-dap-ui',
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  config = function()
    require 'configs.nvim-dap-ui'
  end,
}
