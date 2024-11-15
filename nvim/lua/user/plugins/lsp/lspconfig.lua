return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")

		-- import mason_lspconfig plugin
		local mason_lspconfig = require("mason-lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		local mason_registry = require("mason-registry")

		-- Find the JDTLS package in the Mason Regsitry
		-- local jdtls = mason_registry.get_package("jdtls")
		-- -- Find the full path to the directory where Mason has downloaded the JDTLS binaries
		-- local jdtls_path = jdtls:get_install_path()
		-- -- Obtain the path to the jar which runs the language server
		-- local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
		-- -- Declare white operating system we are using, windows use win, macos use mac
		-- local SYSTEM = "MAC"
		-- -- Obtain the path to configuration files for your specific operating system
		-- local os_config = jdtls_path .. "/config_" .. SYSTEM
		-- -- Obtain the path to the Lomboc jar
		-- local lombok = jdtls_path .. "/lombok.jar"

		local home = os.getenv("HOME")

		local workspace_path = home .. "/code/workspace/"
		-- Determine the project name
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		-- Create the workspace directory by concatenating the designated workspace path and the project name
		local workspace_dir = workspace_path .. project_name

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		mason_lspconfig.setup_handlers({
			-- default handler for installed servers
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
				})
			end,
			["svelte"] = function()
				-- configure svelte server
				lspconfig["svelte"].setup({
					capabilities = capabilities,
					on_attach = function(client, bufnr)
						vim.api.nvim_create_autocmd("BufWritePost", {
							pattern = { "*.js", "*.ts" },
							callback = function(ctx)
								-- Here use ctx.match instead of ctx.file
								client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
							end,
						})
					end,
				})
			end,
			["ts_ls"] = function()
				lspconfig["ts_ls"].setup({
					capabilities = capabilities,
					filetypes = {
						"typescript",
						"typescriptreact",
						"typescript.tsx",
						"javascript",
						"javascriptreact",
						"javascript.jsx",
					},
					root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
					init_options = {
						preferences = {
							importModuleSpecifierPreference = "relative",
							jsxAttributeCompletionStyle = "auto",
						},
					},
				})
			end,
			["pylsp"] = function()
				lspconfig["pylsp"].setup({
					capabilities = capabilities,
					settings = {
						pylsp = {
							plugins = {
								black = { enabled = true },
								pylint = { enabled = true, executable = "pylint" },
							},
						},
					},
				})
			end,
			["graphql"] = function()
				-- configure graphql language server
				lspconfig["graphql"].setup({
					capabilities = capabilities,
					filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
				})
			end,
			["emmet_ls"] = function()
				-- configure emmet language server
				lspconfig["emmet_ls"].setup({
					capabilities = capabilities,
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"svelte",
					},
				})
			end,
			["clangd"] = function()
				lspconfig["clangd"].setup({
					capabilities = capabilities,
					cmd = {
						"clangd",
						"--compile-commands-dir=./",
						"--background-index",
						"--pch-storage=memory",
						"--all-scopes-completion",
						"--pretty",
						"--header-insertion=never",
						"-j=4",
						"--inlay-hints",
						"--header-insertion-decorators",
						"--function-arg-placeholders",
						"--completion-style=detailed",
					},
					filetypes = { "c", "cpp", "objc", "objcpp" },
				})
			end,
			-- ["jdtls"] = function()
			-- 	lspconfig.jdtls.setup({
			-- 		capabilities = capabilities,
			-- 		cmd = {
			-- 			"java",
			-- 			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
			-- 			"-Dosgi.bundles.defaultStartLevel=4",
			-- 			"-Declipse.product=org.eclipse.jdt.ls.core.product",
			-- 			"-Dlog.protocol=true",
			-- 			"-Dlog.level=ALL",
			-- 			"-Xmx2g",
			-- 			"--add-modules=ALL-SYSTEM",
			-- 			"--add-opens",
			-- 			"java.base/java.util=ALL-UNNAMED",
			-- 			"--add-opens",
			-- 			"java.base/java.lang=ALL-UNNAMED",
			-- 			"-javaagent:" .. lombok,
			-- 			"-jar",
			-- 			launcher,
			-- 			"-configuration",
			-- 			os_config,
			-- 			"-data",
			-- 			workspace_dir,
			-- 		},
			-- 		settings = {
			-- 			java = {
			-- 				format = {
			-- 					enabled = true,
			-- 					settings = {
			-- 						url = vim.fn.stdpath("config") .. "/lang_servers/intellij-java-google-style.xml",
			-- 						profile = "GoogleStyle",
			-- 					},
			-- 				},
			-- 				eclipse = { downloadSource = true },
			-- 				maven = { downloadSources = true },
			-- 				signatureHelp = { enabled = true },
			-- 				-- contentProvider = { preferred = "fernflower" },
			-- 				saveActions = { organizeImports = true },
			-- 				completion = {
			-- 					favoriteStaticMembers = {
			-- 						"org.hamcrest.MatcherAssert.assertThat",
			-- 						"org.hamcrest.Matchers.*",
			-- 						"org.hamcrest.CoreMatchers.*",
			-- 						"org.junit.jupiter.api.Assertions.*",
			-- 						"java.util.Objects.requireNonNull",
			-- 						"org.mockito.Mockito.*",
			-- 					},
			-- 					filteredTypes = {
			-- 						"com.sun.*",
			-- 						"io.micrometer.shaded.*",
			-- 						"java.awt.*",
			-- 						"jdk.*",
			-- 						"sun.*",
			-- 					},
			-- 					importOrder = { "java", "jakarta", "javax", "com", "org" },
			-- 				},
			-- 				sources = { organizeImports = { starThreshold = 9999, staticThreshold = 9999 } },
			-- 				codeGeneration = {
			-- 					toString = {
			-- 						template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
			-- 					},
			-- 					hashCodeEquals = { useJava7Objects = true },
			-- 					useBlocks = true,
			-- 				},
			-- 			},
			-- 			configuration = { updateBuildConfiguration = "interactive" },
			-- 			referencesCodeLens = { enabled = true },
			-- 			inlayHints = { parameterNames = { enabled = "all" } },
			-- 		},
			-- 	})
			-- end,
			["lua_ls"] = function()
				-- configure lua server (with special settings)
				lspconfig["lua_ls"].setup({
					capabilities = capabilities,
					settings = {
						Lua = {
							-- make the language server recognize "vim" global
							diagnostics = {
								globals = { "vim" },
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				})
			end,
		})
	end,
}
