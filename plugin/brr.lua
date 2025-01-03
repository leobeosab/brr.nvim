local M = {}

-- Add command for toggling scratch file
-- Add command for adding scratch file
--  Should have global and local modes
-- Add command for selecting scratch file
-- Add command to open given scratch file
--
-- Things to figure out
-- How to store scratch file information
--  Maybe a local ~/.scratches file?
--    Could do json
-- How to handle how the scratch file is opened
--  Multiple commands or settings to define how all scratch files are opened/set
--  Maybe a per scratch config? ( maybe later )

M.setup = function()
  -- nothing
end

local function createFloatingWindow()
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

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  local win = vim.api.nvim_open_win(buf, true, winConfig)

  return { buf, win }
end

createFloatingWindow()


return M
