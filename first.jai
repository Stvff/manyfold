#run build();

exe_name :: "manyfold";
do_run_when_done := true;

build :: () {
	defer set_build_options_dc(.{do_output = false, write_added_strings=false});

	workspace := compiler_create_workspace("Build the program");

	options := get_build_options(); {
		options.output_executable_name = exe_name;
		options.backend = .X64;
		if options.backend == .LLVM then set_optimization(*options, .VERY_OPTIMIZED);
	} set_build_options(options, workspace);

	{ /* checking for messages (to see when it's done, so that we don't run before it's done) */
		intercept_flags: Intercept_Flags;
		compiler_begin_intercept(workspace, intercept_flags);
		defer compiler_end_intercept(workspace);

		add_build_file("main.jai", workspace);

		while true {
			message := compiler_wait_for_message();
			if message.kind == {
				case .COMPLETE; break;
				case .ERROR;
					do_run_when_done = false;
					continue;
			}
		}
	}

/*	if do_run_when_done { /* run the built exe */
		process_result, output_string, error_string, timeout_reached := Process.run_command(sprint("./%", exe_name));
		if process_result.exit_code != 0 {
			log_error("%", error_string);
			exit(1);
		}
	}*/
}

Process :: #import "Process";
#import "Compiler";
#import "Basic";
