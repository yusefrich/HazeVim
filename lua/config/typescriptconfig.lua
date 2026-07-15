return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		local lsp = extra.name or "vtsls"
		local servers = { "tsserver", "ts_ls", "vtsls", "tsgo", lsp }
		for _, server in ipairs(servers) do
			opts.servers[server] = opts.servers[server] or {}
			opts.servers[server].enabled = server == lsp
		end
	end,
}
