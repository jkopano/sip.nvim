-- sip.nvim

local Config = require("sip.config")
local fzf = require("fzf-lua")
local uv = vim.uv or vim.loop

local M = {}
M._active = false

local e = vim.fn.fnameescape

---@param opts? {branch?: boolean}
function M.current(opts)
  opts = opts or {}
  local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
  if Config.options.branch and opts.branch ~= false then
    local branch = M.branch()
    if branch and branch ~= "main" and branch ~= "master" then
      name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
    end
  end
  return Config.options.dir .. name .. ".vim"
end

function M.setup(opts)
  Config.setup(opts)
  M.start()
end

function M.fire(event)
  vim.api.nvim_exec_autocmds("User", {
    pattern = "Persistence" .. event,
  })
end

function M.active()
  return M._active
end

function M.start()
  M._active = true
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("sip", { clear = true }),
    callback = function()
      M.fire("SavePre")

      if Config.options.need > 0 then
        local bufs = vim.tbl_filter(function(b)
          if vim.bo[b].buftype ~= "" or vim.tbl_contains({ "gitcommit", "gitrebase", "jj" }, vim.bo[b].filetype) then
            return false
          end
          return vim.api.nvim_buf_get_name(b) ~= ""
        end, vim.api.nvim_list_bufs())
        if #bufs < Config.options.need then
          return
        end
      end

      M.save()
      M.fire("SavePost")
    end,
  })
end

function M.stop()
  M._active = false
  pcall(vim.api.nvim_del_augroup_by_name, "sip")
end

function M.save()
  vim.cmd("mks! " .. e(M.current()))
end

---@param opts? { last?: boolean }
function M.load(opts)
  opts = opts or {}
  ---@type string
  local file
  if opts.last then
    file = M.last()
  else
    file = M.current()
    if vim.fn.filereadable(file) == 0 then
      file = M.current({ branch = false })
    end
  end
  if file and vim.fn.filereadable(file) ~= 0 then
    M.fire("LoadPre")
    vim.cmd("silent! source " .. e(file))
    M.fire("LoadPost")
  end
end

---@return string[]
function M.list()
  local sessions = vim.fn.glob(Config.options.dir .. "*.vim", true, true)
  table.sort(sessions, function(a, b)
    return uv.fs_stat(a).mtime.sec > uv.fs_stat(b).mtime.sec
  end)
  return sessions
end

function M.last()
  return M.list()[1]
end

function M.select()
  ---@type { session: string, dir: string, branch?: string }[]
  local items = {}
  local have = {} ---@type table<string, boolean>
  for _, session in ipairs(M.list()) do
    if uv.fs_stat(session) then
      local file = session:sub(#Config.options.dir + 1, -5)
      local dir, branch = unpack(vim.split(file, "%%", { plain = true }))
      dir = dir:gsub("%%", "/")
      if jit.os:find("Windows") then
        dir = dir:gsub("^(%w)/", "%1:/")
      end
      if not have[dir] then
        have[dir] = true
        items[#items + 1] = { session = session, dir = dir, branch = branch }
      end
    end
  end

  local display_items = vim.tbl_map(function(item)
    local label = vim.fn.fnamemodify(item.dir, ":p:~")
    return { label = label, value = item }
  end, items)

  fzf.fzf_exec(
    vim.tbl_map(function(i)
      return i.label
    end, display_items),
    {
      prompt = "Select session> ",
      actions = {
        ["default"] = function(selected)
          for _, item in ipairs(display_items) do
            if item.label == selected[1] then
              vim.fn.chdir(item.value.dir)
              M.load()
              break
            end
          end
        end,
      },
    }
  )
end

---@return string?
function M.branch()
  if uv.fs_stat(".git") then
    local ret = vim.fn.systemlist("git branch --show-current")[1]
    return vim.v.shell_error == 0 and ret or nil
  end
end

return M
