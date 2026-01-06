local function compile_blade_parser()
  local plugin_path = vim.fn.stdpath("data") .. "/lazy/tree-sitter-blade"
  local parser_path = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser"
  local cmd = string.format(
    "cd %s && clang -o %s/blade.so -bundle -fPIC -Os -I src -I src/tree_sitter src/parser.c src/scanner.c",
    plugin_path,
    parser_path
  )
  vim.fn.system(cmd)
end

return {
  "EmranMR/tree-sitter-blade",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "blade" },
  build = compile_blade_parser,
  config = function()
    -- Register blade parser config (for TSInstall reference)
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.blade = {
      install_info = {
        url = vim.fn.stdpath("data") .. "/lazy/tree-sitter-blade",
        files = { "src/parser.c", "src/scanner.c" },
      },
      filetype = "blade",
    }

    -- Recompile parser if it fails to load (fixes breakage after nvim-treesitter updates)
    local ok = pcall(vim.treesitter.language.inspect, 'blade')
    if not ok then
      compile_blade_parser()
    end

    -- Ensure php_only parser is installed (required for {{ }} highlighting)
    vim.defer_fn(function()
      local php_ok = pcall(vim.treesitter.language.inspect, 'php_only')
      if not php_ok then
        vim.cmd('TSInstall php_only')
      end
    end, 100)

    -- Set up blade filetype detection
    vim.filetype.add({
      pattern = {
        [".*%.blade%.php"] = "blade",
      },
    })

    -- Enable treesitter for blade files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "blade",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
