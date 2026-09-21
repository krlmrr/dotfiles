return {
  'saghen/blink.cmp',
  version = '*',
  opts = {
    keymap = {
      preset = 'none',
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-n>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback' },
      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
      ['<CR>'] = { 'accept', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
    },
    completion = {
      list = { selection = { auto_insert = false } },
      menu = {
        draw = {
          columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } },
        },
      },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    sources = {
      default = { 'lsp', 'path', 'buffer' },
      providers = {
        lsp = { name = 'LSP', max_items = 5 },
        path = { name = 'Path', max_items = 3 },
        buffer = { name = 'Buffer', max_items = 3 },
      },
    },
    signature = { enabled = true },
  },
}
