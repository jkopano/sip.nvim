<div align = "center">

<h1>sip.nvim</h1>

<p align="center">
  <img src="https://img.shields.io/github/stars/dpi0/sip.nvim?style=flat-square&color=yellow" alt="Stars">
  <img src="https://img.shields.io/github/forks/dpi0/sip.nvim?style=flat-square" alt="Forks">
  <img src="https://img.shields.io/github/contributors/dpi0/sip.nvim?style=flat-square&color=pink" alt="Contributors">
  <img src="https://img.shields.io/github/license/dpi0/sip.nvim?style=flat-square" alt="License">
</p>

<h4>sip is a simple lua plugin for automated session management.</h4>

![screenshot-sip](https://github.com/user-attachments/assets/44b8dcff-8e50-46f5-b910-6082a641e40c)

</div>

## ✨ Features

- automatically saves the active session under `~/.local/state/nvim/sessions` on exit
- simple API to restore the current or last session

## ⚡️ Requirements

- Neovim >= 0.7.2

## ⚡ Installation

[lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "dpi0/sip.nvim",
    dependencies = { "ibhagwan/fzf-lua" }, -- required for session selection.
    lazy = false, -- load immediately (optional)
    config = function()
        require("sip").setup({
            opts = {
                dir = vim.fn.stdpath("state") .. "/sessions/", -- directory where session files are saved
                -- minimum number of file buffers that need to be open to save
                -- Set to 0 to always save
                need = 1,
                branch = true, -- use git branch to save session
                autoload = false, -- automatically load matching session
            },
            keys = {
                {
                  "<leader>sl",
                  function()
                    require("sip").select()
                  end,
                  desc = "Sip: Select session",
                },
                {
                  "<leader>sl",
                  function()
                    require("sip").load()
                  end,
                  desc = "Sip: Load session for current directory",
                },
                {
                  "<leader>sl",
                  function()
                    require("sip").load({ last = true })
                  end,
                  desc = "Sip: Load last session",
                },
                {
                  "<leader>sl",
                  function()
                    require("sip").stop()
                  end,
                  desc = "Sip: Don't save session on exit",
                },
            },
        })
    end
}
```

> [!TIP]
> To configure what should be saved in your session, check [:h 'sessionoptions'](https://neovim.io/doc/user/options.html#'sessionoptions')

## 🚀 Usage

**sip.nvim** works well with plugins like `startify` or `dashboard`. It will never restore a session automatically,
but you can of course write an autocmd that does exactly that if you want.

## 📅 Events

- **SipLoadPre**: before loading a session
- **SipLoadPost**: after loading a session
- **SipSavePre**: before saving a session
- **SipSavePost**: after saving a session
