local _computed = require "__tea.common.computed"

local metadata_file, _ = fs.read_file(_computed.METADATA_VARS.SOURCE)
ami_assert(metadata_file, string.interpolate("failed to load metadata (source: ${SOURCE})", _computed.METADATA_VARS))
local metadata, _ = hjson.parse(metadata_file)
ami_assert(metadata, string.interpolate("failed to parse metadata (source: ${SOURCE})!", _computed.METADATA_VARS))

local offchain_views_file, _ = fs.read_file(_computed.METADATA_VARS.OFFCHAIN_VIEWS)
if offchain_views_file then
	local offchain_views, _ = hjson.parse(offchain_views_file)
	if offchain_views then
		local _readyOcViews = {}
		local _vars = util.merge_tables(_computed.LIGO_VARS, _computed.METADATA_VARS, true)
		local _cmd = _computed.LIGO_VARS.LIGO .. " compile expression" ..
			' ${SYNTAX} ${MODULE}.${name}${OFFCHAIN_VIEW_EXP_SUFFIX} --init-file ${FILE} --michelson-format json --function-body'

		for _, v in ipairs(offchain_views) do
			log_info("Compiling offchain view '${name}'...", v)
			local to_execute = string.interpolate(_cmd, util.merge_tables(_vars, v, true))
			log_trace(to_execute)
			local result, err = proc.exec(to_execute, { stdout = "pipe" })
			ami_assert(result.exit_code == 0, string.interpolate("Failed to compile ${name}!", v))
			local _code = hjson.parse(result.stdout_stream:read("a"))
			local _ocv = util.clone(v, true)
			_ocv.implementations[1].michelsonStorageView.code = _code
			table.insert(_readyOcViews, _ocv)
		end
		metadata.views = _readyOcViews
	else
		log_warn("failed to parse offchain views definition - offchain views wont be included in the contract metadata")
	end
else
	log_warn("failed to load offchain views definition - offchain views won't be included in the contract metadata")
end

fs.write_file("build/metadata.json", hjson.stringify_to_json(metadata, { indent = _computed.METADATA_VARS.INDENT and "\t", sortKeys = true }))