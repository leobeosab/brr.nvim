vim.api.nvim_create_user_command("Scratch", function(params)
  local filename = params.args
  require("brr").open_scratch_file(filename)
end, {nargs = '?'})

vim.api.nvim_create_user_command("ScratchList", function()
  require("brr").open_scratch_list()
end, {})
