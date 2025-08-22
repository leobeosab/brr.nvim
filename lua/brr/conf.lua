local helpers = require("brr.helpers")

---@class brr.Style
---@field title_padding number number of spaces on each side of scratch title
---@field width number decimal value 0-1, 1 is full width, 0 is 0 width
---@field height number decimal value 0-1, 1 is full height, 0 is 0 height

---@class brr.Config
---@field root string
---@field extra_paths string[]
---@field extra_paths_depth number
---@field style brr.Style
local M = {
  root = "~/.scratch_notes/",
  extra_paths = {},
  extra_paths_depth = 1,
  daily_notes_dir = "",
  daily_notes_format = "%Y-%m-%d",
  style = {
    title_padding = 2,
    width = 0.8,
    height = 0.8,
  },

  win_config = {
    relative = "editor",
    border = 'rounded',
    zindex = 2,
    title_pos = "center"
  }
}

function M:apply_user_config(config)
  for k, v in pairs(config) do
    M[k] = helpers.merge(M[k], v)
  end
end

return M
