local _computed = require("__tea.common.computed")

local _deployCmd = "${TEZOS_CLIENT_PATH}" ..
	" originate contract ${CONTRACT_ID} transferring 0 from ${SOURCE} running " ..
	"'${CONTRACT_CODE}' --init '${INITIAL_STORAGE}' --burn-cap ${BURN_CAP} --force"
local _checkCmd = "${TEZOS_CLIENT_PATH}" ..
	" show known contract ${CONTRACT_ID}"

return function(options)
	local _vars = util.merge_tables(_computed.SANDBOX_VARS, {
		TEZOS_CLIENT_PATH = options.path or "octez-client",
		BURN_CAP = options["burn-cap"] or "10",
		CONTRACT_ID = _computed.ID,
		SOURCE = options.source,
		CONTRACT_CODE = string.trim(fs.read_file(string.interpolate("build/${ID}.tz", options))),
		INITIAL_STORAGE = string.trim(fs.read_file(string.interpolate("build/${DEPLOYMENT_ID}-storage-${ID}.tz", options)))
	}, true)
	local _cmd = string.interpolate(_deployCmd, _vars)
	log_debug(_cmd)
	local _ok, _, _code = os.execute(_cmd)
	if not _ok then error("exit code " .. tostring(_code)) end

	local result = proc.exec(string.interpolate(_checkCmd, _vars), { stdout = "pipe" })
	if result.exit_code ~= 0 then error("failed to get deployed contract address") end
	local deploy_file = string.interpolate("deploy/${DEPLOYMENT_ID}-${ID}.json", options)
	local contract_address = string.trim(result.stdout_stream:read("a"))
	local written, _ = fs.write_file(deploy_file, hjson.stringify_to_json({ contractAddress = contract_address }))
	if not written then error("failed to save contract address to '" .. deploy_file .. "'") end
end
