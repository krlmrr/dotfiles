return {
  "EmranMR/tree-sitter-blade",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    -- Register blade parser
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.blade = {
      install_info = {
        url = "https://github.com/EmranMR/tree-sitter-blade",
        files = { "src/parser.c" },
        branch = "main",
      },
      filetype = "blade",
    }

    -- Set up blade filetype detection
    vim.filetype.add({
      pattern = {
        [".*%.blade%.php"] = "blade",
      },
    })

    -- Install blade parser
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "blade",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
