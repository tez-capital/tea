return {
	title = "TEA",
	base = "base",
	commands = {
		setup = {
			description = "TEA 'setup' sub command",
			summary = "Downloads latest ligo library and required dependencies for TEA operation",
			action = "__tea/.cmd/setup.lua",
			contextFailExitCode = EXIT_SETUP_ERROR
		},
		compile = {
			description = "TEA 'compile' sub command",
			summary = 'Runs all compile stages',
			options = {
				clean = { description = "Clean build directory before compilation" },
				contract = { description = "Compiles contract to tz and json" },
				storage = { description = "Compiles initial contract storage" },
				metadata = { description = "Generates contract metadata" },
				jsmodule = { description = "Compiles js module" }
			},
			action = function(_options, _, _, _)
				local _noOptions = #table.keys(_options) == 0
				if _noOptions or _options.clean then
					local _entries = fs.read_dir("build", { return_full_paths = true }) --[=[@as string[]]=]
					_entries = util.merge_arrays(_entries, fs.read_dir("web/dist", { return_full_paths = true }) --[=[@as string[]]=]) --[=[@as string[]]=]
					for _, _entry in ipairs(_entries) do
						if not _entry:match(".gitkeep$") then
							fs.remove(_entry --[[@as string]], { recurse = true })
						end
					end
				end

				if _noOptions or _options.contract then
					am.execute_extension("__tea/tools/compile/contract.lua", { contextFailExitCode = EXIT_APP_INTERNAL_ERROR })
				end

				if _noOptions or _options.metadata then
					am.execute_extension("__tea/tools/compile/metadata.lua", { contextFailExitCode = EXIT_APP_INTERNAL_ERROR })
				end

				if _noOptions or _options.storage then
					am.execute_extension("__tea/tools/compile/storage.lua", { contextFailExitCode = EXIT_APP_INTERNAL_ERROR })
				end

				if _noOptions or _options.jsmodule then
					os.chdir("web")
					am.execute_external("npm", { "run", "build" })
					os.chdir("..")
				end
				log_success("compilation stage complete.")
			end,
			contextFailExitCode = EXIT_APP_INTERNAL_ERROR
		},
		deploy = {
			description = "TEA 'deploy' sub command",
			summary = "Deploys compiled smart contract",
			type = "raw",
			contextFailExitCode = EXIT_APP_START_ERROR,
			action = "__tea/tools/deploy/deploy.lua"
		},
		sandbox = {
			title = "TEA - sandbox",
			description = "TEA 'sandbox' control",
			summary = "Provides ability to control sandbox",
			commands = {
				start = {
					description = "TEA 'start-sandbox' sub command",
					summary = "Starts tezos sandbox",
					action = "__tea/tools/sandbox/start.lua",
					contextFailExitCode = EXIT_APP_INTERNAL_ERROR
				},
				stop = {
					description = "TEA 'stop-sandbox' sub command",
					summary = "Stops tezos sandbox",
					action = "__tea/tools/sandbox/stop.lua",
					contextFailExitCode = EXIT_APP_INTERNAL_ERROR
				},
				remove = {
					description = "TEA 'sandbox remove' sub command",
					summary = "Removes tezos sandbox container",
					action = "__tea/tools/sandbox/remove.lua",
					contextFailExitCode = EXIT_APP_INTERNAL_ERROR
				}
			},
			action = function(_, _command, _args, _cli)
				if not _command then am.print_help(_cli, {}); return end
				am.execute(_command, _args)
			end
		},
		test = {
			description = "TEA 'test' sub command",
			summary = "Runs ligo tests",
			action = "__tea/tools/tests/ligo.lua",
			contextFailExitCode = EXIT_APP_INTERNAL_ERROR
		},
		ligo = {
			description = "TEA 'ligo' sub command",
			summary = "Runs ligo binary with provided arguments",
			type = 'external',
            exec = '__tea/bin/ligo',
			environment = {
                HOME = os.cwd()
            },
			context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
		},
		["test-js"] = {
			description = "TEA 'test-js' sub command",
			summary = "Runs ligo tests",
			action = "__tea/tools/tests/js.lua",
			type = "raw",
			contextFailExitCode = EXIT_APP_INTERNAL_ERROR
		},
		["download-dev-metas"] = {
			hidden = true,
			summary = "Downloads ami definitions for autocompletion in TEA development",
			action = "__tea/.ami-definitions/download-dev-metas.lua",
			contextFailExitCode = EXIT_APP_INTERNAL_ERROR
		}
	}
}
