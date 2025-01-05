local M = {}
-- Add command for toggling scratch file
-- Add command for adding scratch file
--  Should have global and local modes
-- Add command for selecting scratch file
-- Add command to open given scratch file
-- Add fancy header/footer
-- Add quit on q
--
-- Things to figure out
-- How to store scratch file information
--  Maybe a local ~/.scratches file?
--    Could do json
-- How to handle how the scratch file is opened
--  Multiple commands or settings to define how all scratch files are opened/set
--  Maybe a per scratch config? ( maybe later )

---@class brr.Config
---@field root string
local options = {
  root = "~/.scratch_notes/"
}

M.setup = function()
  -- nothing
end

---@class brr.ScratchConfig
---@field file? string filename to open

---@param opts brr.ScratchConfig
local function createFloatingWindow(opts)
  opts = opts or {}
  local file = opts.file
  -- Could add to config
  local dateFormat = "%Y-%m-%d"

  if not file then
    file = tostring(os.date(dateFormat))
  end

  local root = vim.fs.normalize(options.root)

  vim.fn.mkdir(root, "-p")

  local filepath = root .. '/' .. file

  local buf = vim.fn.bufadd(filepath)

  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  vim.bo[buf].filetype = "markdown"

  -- set close keymap

  local width = vim.o.columns
  local height = vim.o.lines

  local winConfig = {
    relative = "editor",
    width = width - 8,
    height = height - 8,
    border = 'rounded',
    col = 4,
    row = 4,
    zindex = 2
  }

  local win = vim.api.nvim_open_win(buf, true, winConfig)

  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, false) end, { desc = "Close scratchpad", buffer=buf })

  return { buf, win }
end

createFloatingWindow()


return M
