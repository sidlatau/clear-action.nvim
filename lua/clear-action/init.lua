local M = {}

local config = require("clear-action.config")
local signs = require("clear-action.signs")
local mappings = require("clear-action.mappings")
local actions = require("clear-action.actions")
local popup = require("clear-action.popup")

M.setup = function(options)
  config.setup(options)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = config.augroup,
    callback = function(args)
      local bufnr = args.buf
      if config.options.popup.hide_cursor then popup.hide_cursor_autocmd() end
      local cmd = vim.api.nvim_buf_create_user_command
      cmd(bufnr, "CodeActionToggleSigns", signs.toggle_signs, {})
      cmd(bufnr, "CodeActionToggleLabel", signs.toggle_label, {})

      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if not client or not client.supports_method("textDocument/codeAction") then return end

      signs.on_attach(bufnr)
      mappings.on_attach(bufnr, client)
    end,
  })
end

M.code_action = actions.code_action

local orig_handler = vim.lsp.handlers["client/registerCapability"]
vim.lsp.handlers["client/registerCapability"] = function(err, result, ctx)
  local orig_result = orig_handler(err, result, ctx)
  -- register mappings after dynamic registration
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local supports_code_action = client and client.supports_method("textDocument/codeAction")
  if not supports_code_action then return orig_result end

  mappings.on_attach(0, client)
  return orig_result
end

return M
