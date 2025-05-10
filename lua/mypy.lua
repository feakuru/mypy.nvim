M = {}

M.setup = function()
	M.namespace = vim.api.nvim_create_namespace("MypyNvim")

	vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
		group = vim.api.nvim_create_augroup("MypyNvim", { clear = true }),
		pattern = { "*.py", "*.pyi" },
		callback = M.typecheck_current_buffer,
	})
end

M.typecheck_current_buffer = function()
	-- 0 stands for "current buffer"
	vim.diagnostic.reset(M.namespace, 0)
	local buf_path = vim.api.nvim_buf_get_name(0)
	local cmd = "mypy --show-error-end --follow-imports=silent " .. buf_path

	local output = vim.fn.systemlist(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		local diagnostics = {}
		for _, line in ipairs(output) do
			local line_from, col_from, line_to, col_to, severity, message =
				string.match(line, "(%d+):(%d+):(%d+):(%d+): (%a+): (.+)$")
			if
				line_from == nil
				or line_to == nil
				or col_from == nil
				or col_to == nil
				or severity == nil
				or message == nil
			then
				goto continue
			else
				-- vim diagnostic severities:
				-- ERROR = 1,
				-- WARN = 2,
				-- INFO = 3,
				-- HINT = 4,
				local mypy_severities = {}
				mypy_severities["error"] = 2
				mypy_severities["note"] = 4
				table.insert(diagnostics, {
					lnum = tonumber(line_from) - 1,
					col = tonumber(col_from) - 1,
					end_lnum = tonumber(line_to) - 1,
					end_col = tonumber(col_to) - 1,
					message = "mypy: " .. message,
					severity = mypy_severities[severity],
				})
			end
			::continue::
		end
		if #diagnostics > 0 then
			vim.diagnostic.set(M.namespace, 0, diagnostics)
		end
	end
end

return M
