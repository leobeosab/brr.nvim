local M = {}
M.__index = M

function M:new(u)
    u = u or {}

    local window = setmetatable(u, M)
    window.buf = nil
    window.win = nil

    return window
end

function M:get_or_create_buff()
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        return self.buf
    end
    self.buf = vim.api.nvim_create_buf(false, true)

    if self.opts.close_shortcut then
      vim.keymap.set('n', self.opts.close_shortcut,
        function ()
            self:close()
        end,
        { desc = "Close Brr", buffer = self.buf })
    end

    return self.buf
end

function M:focus()
    vim.api.nvim_set_current_win(self.win)
end

function M:create_window()
    local buf = self:get_or_create_buff()

    local win = vim.api.nvim_open_win(buf, self.opts.enter, self.opts.win_config)

    vim.api.nvim_win_set_buf(win, buf)

    self.win = win
end

function M:open(opts)
    self.opts = opts
    local check = self:check_status()

    if check == 0 and opts.enter then
        self:focus()
    end

    -- TODO: make an enum for the window check instead of ints
    if check == -1 then
        print("Opening with no buf, but with win")
    end

    if check == -2 or check == -3 then
        self:create_window()
        return
    end
end

function M:close()
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_delete(self.buf, {})
    end

    if self.win and  vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_close(self.win, true)
    end

    self.buf = nil
    self.win = nil
end

function M:clear_buff()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {})
end

function M:append_to_buffer(lines)
    local c = self:check_status()
    if c == -1 or c == -3 then
        print("Stupyder buff not valid")
        return
    end

    local current_line = vim.api.nvim_buf_line_count(self.buf) - 1

    vim.api.nvim_buf_set_lines(self.buf, current_line, current_line, false, lines)
end

-- Checks to make sure the window and buffer are valid
-- -1 no buf
-- -2 no win
-- -3 neither
-- 0 good
function M:check_status()
    local ret = 0
    if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
        ret = ret - 1
    end

    if not self.win or not vim.api.nvim_win_is_valid(self.win) then
        ret = ret - 2
    end

    return ret
end

return M
