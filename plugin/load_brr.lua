vim.api.nvim_create_user_command("Brr", function(params)
  local filename = params.args
  require("brr").open_scratch_file(filename)
end, {nargs = '?'})

vim.api.nvim_create_user_command("BrrList", function()
  require("brr").open_scratch_list()
end, {})
