--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Setting options ]]
require("options")

-- [[ Treesitter highlighting & indentation ]]
-- nvim-treesitter no longer manages highlighting; it's enabled natively via
-- vim.treesitter.start(). Register it at startup (not inside a lazy config) so
-- it applies to every filetype regardless of when nvim-treesitter loads.
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

-- Experimental treesitter-based indentation, falling back to vim's regex
-- highlighting for Ruby (as before).
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		if vim.bo.filetype == 'ruby' then
			return
		end
		pcall(function()
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end)
	end,
})

-- [[ Basic Keymaps ]]
require("keymaps")

-- [[ Install `lazy.nvim` plugin manager ]]
require("lazy-bootstrap")

-- [[ Configure and install plugins ]]
require("lazy-plugins")

-- Expose nvim-treesitter's bundled highlight queries on the runtimepath.
-- lazy.nvim only adds a plugin's root to rtp (never its `runtime/` dir), so
-- this version's queries at runtime/queries/* are otherwise never found when
-- the install dir (~/.local/share/nvim/site) is empty — e.g. when the
-- `tree-sitter` CLI isn't available to run :TSInstall/:TSUpdate.
local ok_rt, runtime_path = pcall(function()
	return require("nvim-treesitter.install").get_package_path("runtime")
end)
local ts_runtime = ok_rt and runtime_path or (vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime")
if vim.fn.isdirectory(ts_runtime) == 1 then
	vim.opt.rtp:append(ts_runtime)
end

vim.cmd.colorscheme("catppuccin")

vim.filetype.add({
	pattern = {
		[".*.typ"] = "typst",
	},
})

--require('sg').setup {
-- Pass your own custom attach function
--    If you do not pass your own attach function, then the following maps are provide:
--        - gd -> goto definition
--        - gr -> goto references
--on_attach = your_custom_lsp_attach_function
--}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
