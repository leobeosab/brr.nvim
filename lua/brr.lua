local M = {}
-- Add command for toggling scratch file
-- Add command for adding scratch file
--  Should have global and local modes
-- Add command for selecting scratch file
-- Add command to open given scratch file
--
-- Things to figure out
-- How to handle how the scratch file is opened
--  Multiple commands or settings to define how all scratch files are opened/set
--  Maybe a per scratch config? ( maybe later )

---@class brr.Style
---@field padding number

---@class brr.Config
---@field root string
---@field style brr.Style
local options = {
  root = "~/.scratch_notes/",
  style = {
    padding = 2
  }
}

M.setup = function()
  -- nothing
end


M.close_scratch_window = function(win, buf)
  return function()
    vim.api.nvim_win_close(win, false)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end


---@class brr.ScratchConfig
---@field file? string filename to open

---@param opts brr.ScratchConfig
M.open_scratch_file = function(opts)
  opts = opts or {}
  local file = opts.file
  -- Could add to config
  local date_format = "%Y-%m-%d"

  if not file then
    file = tostring(os.date(date_format)) .. ".md"
  end

  local root = vim.fs.normalize(options.root)

  vim.fn.mkdir(root, "-p")

  local filepath = root .. '/' .. file

  local buf = vim.fn.bufadd(filepath)

  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  vim.bo[buf].filetype = "markdown"

  local padding = string.rep(" ", options.style.padding)
  local title = padding .. file .. padding

  local width = vim.o.columns
  local height = vim.o.lines


  local win_config = {
    relative = "editor",
    width = width - 8,
    height = height - 8,
    border = 'rounded',
    col = 4,
    row = 4,
    zindex = 2,
    title = title,
    title_pos = "center"
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  vim.keymap.set('n', 'q', M.close_scratch_window(win, buf), { desc = "Close scratchpad", buffer=buf })


  -- Write to file on buf hidden
  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("brr_scratch_autowrite" .. buf, { clear = true }),
    buffer = buf,
    callback = function()
      vim.cmd('write')
    end
  })

  return { buf, win }
end

return M
