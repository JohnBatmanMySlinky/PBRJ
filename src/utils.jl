function jmfp(fp::String)
	sys_apple = Sys.isapple()
	sys_linux = Sys.islinux()

	if !(sys_apple || sys_linux)
		print("get off windows\n")
		@assert false
	end
	
	fp_apple = occursin("Users", fp)
	fp_linux = occursin("home", fp)

	if !(fp_apple || fp_linux)
		print("bad input string\n")
		@assert false
	end
	

	if fp_apple && sys_linux
		fp = replace(fp, "Users" => "home")
		fp = replace(fp, "johnmyslinski" => "jmyslinski")
		fp = replace(fp, "Documents" => "random_stuff")
	elseif fp_linux && sys_apple
		fp = replace(fp, "home" => "Users")
		fp = replace(fp, "jmyslinski" => "johnmyslinski")
		fp = replace(fp, "random_stuff" => "Documents")
	end
	return fp
end
