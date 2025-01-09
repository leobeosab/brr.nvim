local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local conf = require("telescope.config").values

local M = {}
-- Add command for toggling scratch file
-- Add command for adding scratch file
--  Should have global and local modes
-- Add command for selecting scratch file
-- Add command to open given scratch file
-- Add resize listeners
--
-- Maybes?
--  Optional config for daily files ( where no filename is passed and we use the date instead )

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

local window_config = {
  relative = "editor",
  border = 'rounded',
  col = 4,
  row = 4,
  zindex = 2,
  title_pos = "center"
}

local window = nil

M.setup = function()
  -- nothing
end

---@return string current date
local get_current_date = function()
  local date_format = "%Y-%m-%d"
  return tostring(os.date(date_format)) .. ".md"
end

-- If win_id is passed in it will return true if the buff is loaded in the window
---@param filepath string filepath for file
---@param win_id? number vim api window_id
---@return number|nil buff number or nil
local check_if_buffer_is_opened = function(filepath, win_id)
  local normalized_path = vim.fs.normalize(filepath)
  local buf = nil

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      goto continue
    end

    local normalized_buff = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
    if normalized_buff == normalized_path then
      buf = bufnr
      break
    end

    ::continue::
  end

  if buf and win_id then
    local win_buff = vim.api.nvim_win_get_buf(win_id)
    buf = win_buff == buf and buf or nil
  end

  return buf
end

M.scratch_file_list = function()
  local normalized_path = vim.fs.normalize(options.root)
  local file_iterator = vim.fs.dir(normalized_path)
  local files = {}

  local file = file_iterator()
  while file ~= nil do
    files[#files+1] = { normalized_path .. "/" .. file, file }
    file = file_iterator()
  end

  return files
end

-- Uses Telescope for now, I might make this an optional dependency
M.open_scratch_list = function()
  pickers.new({}, {
    prompt_title = "Scratch Files",
    finder = finders.new_table {
      results = M.scratch_file_list(),
      entry_maker = function(entry)
        print(entry[1])
        return {
          value = entry,
          display = entry[2],
          ordinal = entry[2],
          filename = entry[1],
        }
      end
    },
    previewer = conf.file_previewer({})
  }):find()
end


---@param win number window id
---@param buf number buffer id
M.close_scratch_file = function(win, buf)
  return function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end


---@param file? string
M.open_scratch_file = function(file)
  if not file then
    file = get_current_date()
  end

  local root = vim.fs.normalize(options.root)

  vim.fn.mkdir(root, "-p")

  local filepath = root .. '/' .. file

  -- If buf is already open, close window
  local buf = check_if_buffer_is_opened(filepath, window)
  if buf and window then
    M.close_scratch_file(window, buf)()
    return
  end

  buf = vim.fn.bufadd(filepath)

  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  vim.bo[buf].filetype = "markdown"

  -- Write to file on buf hidden
  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("brr_scratch_autowrite" .. buf, { clear = true }),
    buffer = buf,
    callback = function()
      vim.cmd('write')
    end
  })

  local padding = string.rep(" ", options.style.padding)
  local title = padding .. file .. padding

  local width = vim.o.columns
  local height = vim.o.lines

  local config = vim.fn.deepcopy(window_config)
  config.width = width - 8
  config.height = height - 8
  config.title = title


  if window and vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_win_set_buf(window, buf)
  else
    window = vim.api.nvim_open_win(buf, true, config)
  end

  vim.keymap.set('n', 'q', M.close_scratch_file(window, buf), { desc = "Close scratchpad", buffer=buf })

  return { buf }
end

return M
