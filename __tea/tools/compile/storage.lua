local computed = require "__tea.common.computed"

local cmd = computed.LIGO_VARS.LIGO ..
	" compile storage ${FILE} --module ${MODULE} '${MODULE}.generate_initial_storage(${INITIAL_STORAGE_ARGS})'" ..
	" --michelson-format \\${FORMAT} --output-file ${BUILD_DIR}/${DEPLOY}-storage-${CONTRACT_ID}\\${SUFFIX} ${SYNTAX_ARG}"

function string.tohex(str)
	return (str:gsub('.', function (c)
		return string.format('%02x', string.byte(c))
	end))
end

for id, vars in pairs(computed.DEPLOYS) do
	local metadata, _ = fs.read_file("build/metadata.json")
	if not metadata then
		log_warn("failed to read metadata from 'build/metadata.json' - 'metadata' argument wont be available during initial storage generation)")
	end
	metadata = "0x" .. string.tohex(metadata) -- get hex
	vars = util.merge_tables(computed.LIGO_VARS, vars, true)
	vars = util.merge_tables(vars, { DEPLOY = id, metadata = metadata or nil --[[requires 2 pass]] }, true)
	-- first pass - replace common
	local preprocessed_cmd = string.interpolate(cmd, vars)
	if computed.COMPILE.TZ then
		local _vars = util.merge_tables(vars, {
			FORMAT = "text",
			SUFFIX = ".tz",
		})
		log_info("Compiling initial storage tz for ${DEPLOY}...", _vars)
		local to_execute = string.interpolate(preprocessed_cmd, _vars)
		log_trace(to_execute)
		local ok = os.execute(to_execute)
		ami_assert(ok,
			string.interpolate("Failed to compile contract ${BUILD_DIR}/${DEPLOY}-storage-${CONTRACT_ID}.tz", _vars))
	end

	if computed.COMPILE.JSON then
		local _vars = util.merge_tables(vars, {
			FORMAT = "json",
			SUFFIX = ".json",
		})
		log_info("Compiling initial storage json for ${DEPLOY}...", _vars)
		local to_execute = string.interpolate(preprocessed_cmd, _vars)
		log_trace(to_execute)
		local ok = os.execute(to_execute)
		ami_assert(ok,
			string.interpolate("Failed to compile contract ${BUILD_DIR}/${DEPLOY}-storage-${CONTRACT_ID}.tz", computed))
	end
end
