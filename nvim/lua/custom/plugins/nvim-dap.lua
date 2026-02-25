return {
  -- Debug Framework
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
  },
  config = function()
    require 'configs.nvim-dap'
  end,
  event = 'VeryLazy',
}
