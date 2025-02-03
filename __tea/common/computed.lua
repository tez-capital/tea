-- containers
local function _get_container_engine()
	local _prefers = am.app.get_configuration({ "containers", "engine" })
	if type(_prefers) == "string" then return _prefers end
	-- we prefer rootless setups so podman by default
	if os.execute "podman --version > /dev/null 2>&1" then
		return "podman"
	end
	if os.execute "docker --version > /dev/null 2>&1" then
		return "docker"
	end
	return nil
end

local _containerEngine = _get_container_engine()

-- ligo
local _ligoContainer = type(am.app.get_configuration({ "ligo", "image" })) == "string"
local _globalLigo = am.app.get_configuration({ "ligo", "global" }, false) == true
local _syntax = am.app.get_configuration({ "ligo", "syntax" }, "cameligo")
local function _get_ligo_cmd()
	if _ligoContainer then
		return string.interpolate('${ENGINE} run --rm -v "$PWD":"$PWD" -w "$PWD" ${IMAGE}', {
			ENGINE = _containerEngine,
			IMAGE = _ligoContainer
		})
	end
	if _globalLigo then
		return "ligo"
	end
	return "./__tea/bin/ligo"
end

local function _find_file(dir, name)
	local _candidates = fs.read_dir(dir, { returnFullPaths = true, asDirEntries = true })
	for _, candidate in ipairs(_candidates) do
		if string.match(candidate:name(), "^" .. name) then
			return candidate:fullpath()
		end
	end
	return "src/contract.mligo"
end

local _deploys = am.app.get_configuration("deploys", {})
for _, v in pairs(_deploys) do
	v.INITIAL_STORAGE_ARGS = am.app.get_configuration({ "ligo", "initial-storage-args" },
		"(${admin-addr}: address), ${metadata}")
end

return {
	ID = am.app.get("id", "tea-contract"),
	USE_LIGO_CONTAINER = _ligoContainer,
	USE_GLOBAl_LIGO = _globalLigo,
	CONTAINER_ENGINE = _containerEngine,
	SANDBOX_VARS = {
		ENGINE = _containerEngine,
		NAME = am.app.get_configuration({ "sandbox", "name" }, "snadbox-" .. am.app.get("id", "tezos")),
		IMAGE = am.app.get_configuration({ "sandbox", "image" }, "oxheadalpha/flextesa:latest"),
		SCRIPT = am.app.get_configuration({ "sandbox", "script" }, "kathmandubox"),
		RPC_PORT = am.app.get_configuration({ "sandbox", "rpc_port" }, "20000")
	},
	LIGO_VARS = {
		LIGO = _get_ligo_cmd(),
		CONTRACT_ID = am.app.get("id", "tea-contract"),
		FILE = am.app.get_configuration({ "ligo", "contract-file" }, _find_file("src", "contract")),
		SYNTAX = _syntax,
		SYNTAX_ARG = "--syntax " .. _syntax,
		BUILD_DIR = am.app.get_configuration({ "ligo", "build-directory" }, "build"),
		MODULE = am.app.get_configuration({ "ligo", "module" }, "C"),
	},
	DEPLOYS = _deploys,
	COMPILE = {
		TZ   = am.app.get_configuration({ "compile", "tz" }, true),
		JSON = am.app.get_configuration({ "compile", "json" }, true),
	},
	TEST_VARS = {
		ROOT = am.app.get_configuration({ "tests", "root" }, _find_file("tests", "all"))
	},
	METADATA_VARS = {
		SOURCE = am.app.get_configuration({ "metadata", "source" }, "src/metadata.hjson"),
		OFFCHAIN_VIEWS = am.app.get_configuration({ "metadata", "offchain-views" }, "src/offchain-views.hjson"),
		INDENT = am.app.get_configuration({ "metadata", "indent" }, false),
		OFFCHAIN_VIEW_EXP_SUFFIX = am.app.get_configuration({ "metadata", "offchain-view-expression-suffix" },
			"_off_chain_view")
	}
}
