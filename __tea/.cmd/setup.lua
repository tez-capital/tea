local _computed = require "__tea.common.computed"

if type(_computed.CONTAINER_ENGINE) ~= "string" then
	log_warn("Failed to detect container engine! You need one to be able to run sandbox.")
	log_info("HINT: For docker see https://docs.docker.com/compose/gettingstarted/")
	log_info("HINT: For podman see https://podman.io/getting-started/installation")
else
	log_info(_computed.CONTAINER_ENGINE .. " detected.")
end

local _ligoDestination = "__tea/bin/ligo"
local function _ligo_download()
	if _computed.USE_LIGO_CONTAINER then
		log_info("'image' in ligo configuration detected. Static ligo binary won't be downloaded.")
	else
		-- download ligo
		local _ligoVersion = am.app.get_configuration({ "ligo", "version" }, "latest")
		if _computed.USE_GLOBAl_LIGO then
			if _ligoVersion ~= "latest" then
				log_warn("You are overwriting global ligo instance with non latest version")
			end

			local _result = proc.exec("which ligo", { stdout = "pipe" })
			if _result.exitcode ~= 0 then -- ligo not in the PATH use default destination
				_ligoDestination = "/usr/local/bin/ligo"
			else
				_ligoDestination = string.trim(_result.stdoutStream:read("a"))
			end
		end

		local _currentLigoVersion = "0.0.0"
		local _result = proc.exec(string.interpolate("${LIGO} version -v", { LIGO = _ligoDestination }), { stdout = "pipe" })
		if _result.exitcode == 0 then
			_currentLigoVersion = string.trim(_result.stdoutStream:read("a"))
		end

		if _ligoVersion ~= "latest" and ver.compare(_currentLigoVersion, _ligoVersion) == 0 then
			log_info("Suitable ligo version already found. Skipping download...")
			return
		end

		log_info("Searching " .. _ligoVersion .. " ligo binary...")
		-- 12294987 ligo project ID
		local _releasesUrl = "https://gitlab.com/api/v4/projects/12294987/releases/" ..
			(_ligoVersion == "latest" and "" or _ligoVersion)
		local _releaseInfo = net.download_string(_releasesUrl)
		if not _releaseInfo then return ami_error("Failed to obtain ligo release info from gitlab.") end
		local _releases = hjson.parse(_releaseInfo)
		local _latest
		if _ligoVersion == "latest" then
			_latest = _releases[1] -- lua indexes from 1 ;)
		else
			_latest = _releases
		end

		if ver.compare(_currentLigoVersion, _latest.tag_name) == 0 then
			log_info("Local ligo matches latest version. Skipping download...")
			return
		end

		local _links = _latest.assets.links
		local _pattern = ("Static Linux binary"):gsub('(%a)', function(v) return '[' .. v:lower() .. v:upper() .. ']' end)
		local _ligoUrl
		for _, link in ipairs(_links) do
			if link.name:match(_pattern) then
				_ligoUrl = link.url
				break
			end
		end
		ami_assert(_ligoUrl,
			"Failed to get static linux binary URL!\nPlease try to specify LIGO_VERSION in configuration section of your app.hjson.")

		log_info("Downloading " .. _latest.tag_name .. " ligo binary...")
		net.download_file(_ligoUrl, _ligoDestination, { show_default_progress = 10 })
		fs.chmod(_ligoDestination, 755)
		log_success("ligo binary downloaded")
	end
end

_ligo_download()

local function _install_dependencies()
	local _packageJsonFile = fs.read_file("package.json", { binaryMode = true })
	local _ok, _parsed = hjson.safe_parse(_packageJsonFile)
	ami_assert(_ok, "Invalid package.json!")
	if #table.keys(_parsed.dependencies) > 0 then
		log_info("Installing ligo dependencies...")
	local _cmd = string.interpolate("${LIGO} install", { LIGO = _ligoDestination })
	log_debug(_cmd)
	ami_assert(os.execute(_cmd),
		"Failed to install ligo dependencies!")
	else
		log_info("No ligo dependencies found. Skipping dependecy setup...")
	end
end
_install_dependencies()