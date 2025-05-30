local M = {}

function M.extend(dest, src)
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

function M.make_unique(list)
  local seen = {}
  local res = {}

  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      table.insert(res, v)
    end
  end

  return res
end

function M.get_files(paths, rec_depth)
  local files = {}

  for _, path in ipairs(paths) do
    local normalized_path = vim.fs.normalize(path)
    local stat = vim.uv.fs_stat(normalized_path)
    if not stat then
      goto continue
    end

    local is_dir = stat.type == "directory"

    if not is_dir then
      local path_split = vim.split(normalized_path, '/')
      local filename = path_split[#path_split]
      files[#files+1] = { normalized_path, filename }
      goto continue
    end

    local file_iterator = vim.fs.dir(normalized_path, { depth = rec_depth, follow = true })

    -- type returned from the vim.fs.dir iterator is always a directory for some reason
    local file = file_iterator()
    while file ~= nil do
      stat = vim.uv.fs_stat(normalized_path .. "/" .. file)
      -- filter only markdown files
      local filetype = string.sub(file, -2, -1)
      if stat and stat.type == "file" and filetype == "md" then
        files[#files + 1] = { normalized_path .. "/" .. file, file }
      end
      file = file_iterator()
    end

    ::continue::
  end

  return M.make_unique(files)
end

return M
