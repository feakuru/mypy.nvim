# mypy.nvim

This is my first Neovim plugin! ;)

Have you ever felt that `mypy` is hard to use organically from within Neovim?
Sure, maybe you have a plugin for your LSP. Or maybe you have worked out the magic of `null-ls` or `none-ls`. Or maybe you even enjoy using a plain old terminal tab where you run your mypy where you want to... but what if you wanted to just have mypy errors as diagnostic warnings and that's it?
Wouldn't it make more sense to just use a separate process (and thus plugin) for that, and have it stay up-to-date while your LSP thinks about other things that are maybe more critical?

I certainly think so. So this is what this plugin does:
* runs `mypy` on your open Python files
* displays the errors from `mypy` as diagnostic warnings and notes as notes (or as diagnostics of custom severities you can provide)
* allows you to toggle/enable/disable itself with `:MypyToggle`, `:MypyEnable`, `:MypyDisable`

## Installation

For Lazy:
```lua
return {
  {
    'feakuru/mypy.nvim',
    config = function()
      require('mypy').setup()
    end,
  },
}
```

You can pass a `config` to the `setup()` call to override some defaults:

```lua
return {
  {
    'feakuru/mypy.nvim',
    config = function()
      require('mypy').setup {
        -- additional arguments to pass to invocations of `mypy`
        -- by default, it is called with `--show-error-end --follow-imports=silent`
        extra_args = {'--check-untyped-defs', '--verbose'},
        -- override mypy diagnostic severities
        -- the default is { error = vim.diagnostic.severity.WARN, note = vim.diagnostic.severity.HINT }
        severities = { error = vim.diagnostic.severity.ERROR, note = vim.diagnostic.severity.INFO },
      }
    end,
  },
}

```

## Contributing

Please feel free to submit helpful PRs or open issues.
