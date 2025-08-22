
local M = {}

local is_dict_like = function(v) -- has string and number keys
  return type(v) == "table" and (vim.tbl_isempty(v) or not svim.islist(v))
end
local is_dict = function(v) -- has only string keys
  return type(v) == "table" and (vim.tbl_isempty(v) or not v[1])
end

-- Stolen from @folke, merge values like tbl_deep_extend but any values
function M.merge(...)
  local ret = select(1, ...)
  for i = 2, select("#", ...) do
    local value = select(i, ...)
    if is_dict_like(ret) and is_dict(value) then
      for k, v in pairs(value) do
        ret[k] = M.config.merge(ret[k], v)
      end
    elseif value ~= nil then
      ret = value
    end
  end
  return ret
end

return M
