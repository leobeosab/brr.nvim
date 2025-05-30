local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local util = require("brr.utils")

local M = {}

---@class brr.Style
---@field title_padding number number of spaces on each side of scratch title
---@field width number decimal value 0-1, 1 is full width, 0 is 0 width
---@field height number decimal value 0-1, 1 is full height, 0 is 0 height

---@class brr.Config
---@field root string
---@field extra_paths string[]
---@field extra_paths_depth number
---@field style brr.Style
local options = {
  root = "~/.scratch_notes/",
  extra_paths = {},
  extra_paths_depth = 1,
  daily_notes_dir = "",
  daily_notes_format = "%Y-%m-%d",
  style = {
    title_padding = 2,
    width = 0.8,
    height = 0.8,
  }
}

local window_config = {
  relative = "editor",
  border = 'rounded',
  zindex = 2,
  title_pos = "center"
}

local window = nil

---@param opts brr.Config
M.setup = function(opts)
  opts = opts or {}
  local style = opts.style or {}
  options.extra_paths = opts.extra_paths or {}
  options.extra_paths_depth = opts.extra_paths_depth or 1

  options.root = opts.root or options.root
  options.daily_notes_dir = opts.daily_notes_dir or options.root
  options.daily_notes_format = opts.daily_notes_format or options.daily_notes_format

  for k, v in pairs(style) do
    options.style[k] = v
  end
end

---@class window_config
---@field width number
---@field height number
---@field col number
---@field row number
local get_win_size = function()
  local vim_width = vim.o.columns
  local vim_height = vim.o.lines

  local win_width = math.floor(vim_width * options.style.width)
  local win_height = math.floor(vim_height * options.style.height)

  local col = math.floor((vim_width - win_width) / 2)
  local row = math.floor((vim_height - win_height) / 2)

  return {
    width = win_width,
    height = win_height,
    col = col,
    row = row
  }
end

---@param win number window id
---@return function
local resize_window = function(win)
  return function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end

    local win_size = get_win_size()
    vim.api.nvim_win_set_config(win, {
      width = win_size.width,
      height = win_size.height,
      row = win_size.row,
      col = win_size.col,
      relative = 'editor',
    })
  end
end

---@return string current date
local get_current_date = function()
  local date_format = options.daily_notes_format
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

  if buf and win_id and vim.api.nvim_win_is_valid(win_id) then
    local win_buff = vim.api.nvim_win_get_buf(win_id)
    buf = win_buff == buf and buf or nil
  end

  return buf
end

-- Uses Telescope for now, I might make this an optional dependency
-- Opens a scratch file list of all files in the root_dir
M.open_scratch_list = function()

  local files = M.scratch_file_list()

  pickers.new({}, {
    prompt_title = "Scratch Files",
    finder = finders.new_table {
      results = files,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[2],
          ordinal = entry[2],
          filename = entry[1],
        }
      end
    },
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        M.open_scratch_file(selection.value[1])
      end)
      return true
    end,
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

M.scratch_file_list = function(paths)
  local pathlist
  if not paths then
    pathlist = util.extend({ options.root, options.daily_notes_dir }, options.extra_paths)
  end

  local files = util.get_files(pathlist, options.extra_paths_depth)
  return files
end


---@param file? string
---@return number buffer id
M.open_scratch_file = function(file)
  local new_path = options.root

  if not file or file == '' then
    file = get_current_date()
    new_path = options.daily_notes_dir
  end

  if window and not vim.api.nvim_win_is_valid(window) then
    window = nil
  end

  local scratch_files = M.scratch_file_list()
  local filepath

  for _, sf in ipairs(scratch_files) do
    if file == sf[1] then
      filepath = sf[1]
    end
  end

  if filepath == nil then
    local p = vim.fs.normalize(new_path)
    vim.fn.mkdir(p, "-p")
    filepath = p .. '/' .. file
  end


  -- If buf is already open, close window
  local buf = check_if_buffer_is_opened(filepath, window)
  if buf and window then
    M.close_scratch_file(window, buf)()
    return -1
  end

  buf = vim.fn.bufadd(filepath)
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })


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

  local padding = string.rep(" ", options.style.title_padding)
  local title = padding .. file .. padding

  local win_size = get_win_size()
  local config = vim.fn.deepcopy(window_config)
  config.width = win_size.width
  config.height = win_size.height
  config.row = win_size.row
  config.col = win_size.col
  config.title = title


  if window and vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_win_set_buf(window, buf)
    vim.api.nvim_win_set_config(window, config)
  else
    window = vim.api.nvim_open_win(buf, true, config)
    vim.api.nvim_create_autocmd("VimResized", {
      callback = resize_window(window)
    })
  end

  vim.keymap.set('n', 'q', M.close_scratch_file(window, buf), { desc = "Close scratchpad", buffer = buf })

  return buf
end

return M
