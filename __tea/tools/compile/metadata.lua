local _computed = require "__tea.common.computed"

local _ok, _metadataFile = fs.safe_read_file(_computed.METADATA_VARS.SOURCE)
ami_assert(_ok, string.interpolate("Failed to load metadata from ${SOURCE}!", _computed.METADATA_VARS))
local _ok, _metadata = hjson.safe_parse(_metadataFile)
ami_assert(_ok, string.interpolate("Failed to parse metadata (source: ${SOURCE})!", _computed.METADATA_VARS))

local _ok, _ocViewsFile = fs.safe_read_file(_computed.METADATA_VARS.OFFCHAIN_VIEWS)
if _ok then
	local _ok, _ocViews = hjson.safe_parse(_ocViewsFile)
	if _ok then
		local _readyOcViews = {}
		local _vars = util.merge_tables(_computed.LIGO_VARS, _computed.METADATA_VARS, true)
		local _cmd = _computed.LIGO_VARS.LIGO .. " compile expression" ..
			' ${SYNTAX} ${name}${OFFCHAIN_VIEW_EXP_SUFFIX} --init-file ${FILE} --michelson-format json --function-body'

		for _, v in ipairs(_ocViews) do
			log_info("Compiling offchain view '${name}'...", v)
			local toExecute = string.interpolate(_cmd, util.merge_tables(_vars, v, true))
			log_trace(toExecute)
			local _result = proc.exec(toExecute, { stdout = "pipe" })
			ami_assert(_result.exitcode == 0, string.interpolate("Failed to compile ${name}!", v))
			local _code = hjson.parse(_result.stdoutStream:read("a"))
			local _ocv = util.clone(v, true)
			_ocv.implementations[1].michelsonStorageView.code = _code
			table.insert(_readyOcViews, _ocv)
		end
		_metadata.views = _readyOcViews
	else
		log_warn("Failed to parse offchain views definition. Offchain views wont be included in the metadata!")
	end
else
	log_warn("Failed to load offchain views definition. Offchain views wont be included in the metadata!")
end

fs.write_file("build/metadata.json", hjson.stringify_to_json(_metadata, { indent = _computed.METADATA_VARS.INDENT and "\t", sortKeys = true }))