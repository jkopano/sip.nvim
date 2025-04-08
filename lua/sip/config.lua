-- sip/config.lua
local M = {}

---@class Sip.Config
local defaults = {
  dir = vim.fn.stdpath("state") .. "/sessions/", -- directory where session files are saved
  need = 1,
  branch = true,
  autoload = false, -- automatically load matching session on startup
}

---@type Sip.Config
M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  vim.fn.mkdir(M.options.dir, "p")
end

return M
