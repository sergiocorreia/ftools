*! version 2.9.0 28mar2017
program ms_get_version
	args ado
	mata: st_local("package_version", get_version("`ado'"))
	c_local package_version "`package_version'"
end

mata:
	string scalar get_version(string scalar ado)
	{
		real scalar fh
		string scalar line
		string scalar fn
		fn = findfile(ado + ".ado", c("adopath"))
		if (fn == "") {
			printf("{err}file not found: %s.ado\n", ado)
			exit(123)
		}
		fh = fopen(fn, "r")
		line = fget(fh)
		fclose(fh)
		line = strtrim(line)
		if (strpos(line, "*! version ")) {
			line = strtrim(substr(line, 1 + strlen("*! version "), .))
			return(line)
		}
		if (strpos(line, sprintf("*! %s ", ado) )) {
			line = strtrim(substr(line, 1 + strlen(sprintf("*! %s ", ado) ), .))
			return(line)
		}
		else {
			printf("{err}no version line found for %s\n", ado)
			return("")
		}
	}
end
