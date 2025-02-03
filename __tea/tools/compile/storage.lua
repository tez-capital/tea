local _computed = require "__tea.common.computed"

local _cmd = _computed.LIGO_VARS.LIGO ..
	" compile storage ${FILE} --module ${MODULE} '${MODULE}.generate_initial_storage(${INITIAL_STORAGE_ARGS})'" ..
	" --michelson-format \\${FORMAT} --output-file ${BUILD_DIR}/${DEPLOY}-storage-${CONTRACT_ID}\\${SUFFIX} ${SYNTAX_ARG}"

function string.tohex(str)
	return (str:gsub('.', function (c)
		return string.format('%02x', string.byte(c))
	end))
end

for id, vars in pairs(_computed.DEPLOYS) do
	local _ok, _metadata = fs.safe_read_file("build/metadata.json")
	if not _ok then
		log_warn("Failed to read metadata from 'build/metadata.json'! ('metadata' argument wont be available during initial storage generation)")
	end
	_metadata = "0x" .. string.tohex(_metadata) -- get hex
	vars = util.merge_tables(_computed.LIGO_VARS, vars, true)
	vars = util.merge_tables(vars, { DEPLOY = id, metadata = _ok and _metadata or nil --[[requires 2 pass]] }, true)
	-- first pass - replace common
	local _preprocessedCmd = string.interpolate(_cmd, vars)
	if _computed.COMPILE.TZ then
		local _vars = util.merge_tables(vars, {
			FORMAT = "text",
			SUFFIX = ".tz",
		})
		log_info("Compiling initial storage tz for ${DEPLOY}...", _vars)
		local toExec = string.interpolate(_preprocessedCmd, _vars)
		log_trace(toExec)
		local _ok = os.execute(toExec)
		ami_assert(_ok,
			string.interpolate("Failed to compile contract ${BUILD_DIR}/${DEPLOY}-storage-${CONTRACT_ID}.tz", _vars))
	end

	if _computed.COMPILE.JSON then
		local _vars = util.merge_tables(vars, {
			FORMAT = "json",
			SUFFIX = ".json",
		})
		log_info("Compiling initial storage json for ${DEPLOY}...", _vars)
		local toExec = string.interpolate(_preprocessedCmd, _vars)
		log_trace(toExec)
		local _ok = os.execute(toExec)
		ami_assert(_ok,
			string.interpolate("Failed to compile contract ${BUILD_DIR}/${DEPLOY}-storage-${CONTRACT_ID}.tz", _computed))
	end
end
