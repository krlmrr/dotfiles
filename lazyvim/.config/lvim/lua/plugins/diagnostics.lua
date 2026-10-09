-- Diagnostic presentation.
--
--  * No icons in the sign column.
--  * "Unnecessary" diagnostics (unused variables, params, imports — the ones the
--    server tags so the text itself renders faded) keep the fade but lose the
--    virtual text off to the right. The fade already says it; the sentence is noise.
--
-- Everything still reaches :lua vim.diagnostic.open_float() and the statusline counts.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        signs = false,
        virtual_text = {
          -- Returning nil drops the diagnostic from the virtual text only.
          format = function(diagnostic)
            if diagnostic._tags and diagnostic._tags.unnecessary then
              return nil
            end
            return diagnostic.message
          end,
        },
      },
    },
  },
}
