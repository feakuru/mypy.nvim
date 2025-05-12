M = {
	extra_args = "",
	severities = { error = vim.diagnostic.severity.WARN, note = vim.diagnostic.severity.HINT },
}

---@class mypy.Config
---@field extra_args string[]: The extra arguments to pass to mypy
---@field severities {string: integer}: The relationship of mypy diagnostic type to a vim.diagnostic.severity.* value

--- The setup function: creates autocommands, user commands and the diagnostic namespace.
---@param config mypy.Config?
M.setup = function(config)
	config = config or {}
	M.namespace = vim.api.nvim_create_namespace("MypyNvim")
	M.enabled = true
	if config.extra_args ~= nil and #config.extra_args > 0 then
		M.extra_args = table.concat(config.extra_args, " ")
	end
	if config.severities ~= nil then
		M.severities = config.severities
	end

	vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
		group = vim.api.nvim_create_augroup("MypyNvim", { clear = true }),
		pattern = { "*.py", "*.pyi" },
		callback = M.typecheck_current_buffer,
	})

	vim.api.nvim_create_user_command("MypyEnable", function(_)
		M.enabled = true
		M.typecheck_current_buffer()
	end, { desc = "Enable Mypy diagnostics" })
	vim.api.nvim_create_user_command("MypyDisable", function(_)
		M.enabled = false
		M.typecheck_current_buffer()
	end, { desc = "Disable Mypy diagnostics" })
	vim.api.nvim_create_user_command("MypyToggle", function(_)
		M.enabled = not M.enabled
		M.typecheck_current_buffer()
	end, { desc = "Toggle Mypy diagnostics" })
end

M.typecheck_current_buffer = function()
	-- 0 stands for "current buffer"
	vim.diagnostic.reset(M.namespace, 0)
	if not M.enabled then
		return
	end
	local buf_path = vim.api.nvim_buf_get_name(0)
	local cmd = "mypy --show-error-end --follow-imports=silent " .. M.extra_args .. " " .. buf_path

	local output = vim.fn.systemlist(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		local diagnostics = {}
		for _, line in ipairs(output) do
			local line_from, col_from, line_to, col_to, severity, message =
				string.match(line, "(%d+):(%d+):(%d+):(%d+): (%a+): (.+)$")
			if
				line_from ~= nil
				and line_to ~= nil
				and col_from ~= nil
				and col_to ~= nil
				and severity ~= nil
				and message ~= nil
			then
				table.insert(diagnostics, {
					lnum = tonumber(line_from) - 1,
					col = tonumber(col_from) - 1,
					end_lnum = tonumber(line_to) - 1,
					end_col = tonumber(col_to) - 1,
					message = "mypy: " .. message,
					severity = M.severities[severity],
				})
			end
		end
		if #diagnostics > 0 then
			vim.diagnostic.set(M.namespace, 0, diagnostics)
		end
	end
end

return M
