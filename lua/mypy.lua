M = {
	extra_args = "",
	severities = { error = vim.diagnostic.severity.WARN, note = vim.diagnostic.severity.HINT },
}

---@class mypy.Config
---@field extra_args? string[]: The extra arguments to pass to mypy
---@field severities? {string: integer}: The relationship of mypy diagnostic type to a vim.diagnostic.severity.* value

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

-- Store current job to prevent too many concurrent Mypy processes.
-- nil means no job
M.current_job = nil

M.typecheck_current_buffer = function()
	if not M.enabled then
		vim.diagnostic.reset(M.namespace, 0)
		return
	end

	-- Kill any running jobs before starting a new one.
	if M.current_job then
		M.current_job:kill(9)
		M.current_job = nil
	end

	local buf_num = vim.api.nvim_get_current_buf()
	local buf_path = vim.api.nvim_buf_get_name(0)
	local cmd_raw = "mypy --show-error-end --follow-imports=silent " .. M.extra_args .. " " .. buf_path
	local cmd = {}
	for w in string.gmatch(cmd_raw, "%S+") do
		table.insert(cmd, w)
	end

	local job
	local ok, job_result = pcall(vim.system, cmd, {}, function(out)
		-- Mark previous job as finished.
		if M.current_job ~= job then
			return
		end
		M.current_job = nil
		do
			if out.code ~= 0 then
				local diagnostics = {}
				for line_from, col_from, line_to, col_to, severity, message in
					string.gmatch(out.stdout, "(%d+):(%d+):(%d+):(%d+): (%a+): ([^\n]+)")
				do
					table.insert(diagnostics, {
						lnum = tonumber(line_from) - 1,
						col = tonumber(col_from) - 1,
						end_lnum = tonumber(line_to) - 1,
						end_col = tonumber(col_to) - 1,
						message = "mypy: " .. message,
						severity = M.severities[severity],
					})
				end
				vim.schedule(function()
					vim.diagnostic.set(M.namespace, buf_num, diagnostics)
				end)
			else
				vim.schedule(function()
					vim.diagnostic.reset(M.namespace, buf_num)
				end)
			end
		end
	end)

	if ok then
		job = job_result
		M.current_job = job
	end
end

return M
