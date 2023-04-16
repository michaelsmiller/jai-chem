#import "Basic";
#import "Compiler";

EXECUTABLE_NAME :: "main";

build :: () {
  w := compiler_create_workspace(); // isolated environment
  if !w {
    print("Workspace creation failed!\n");
    return;
  }

  options := get_build_options(); // defaults + current command line options
  options.output_executable_name = EXECUTABLE_NAME;
  options.backend = .X64; // Compile directly to x64 instead of with LLVM
  options.optimization_level = .DEBUG; // debug build, array bounds checking, no optimizations
  // options.optimization_level = .RELEASE;

  // Add local modules/ path to import_paths
  import_path : [..] string;
  defer array_free(import_path);
  array_add(*import_path, ..options.import_path);
  array_add(*import_path, "src");
  options.import_path = import_path;

  set_build_options(options, w); // must happen before we start compiling

  compiler_begin_intercept(w);
  add_build_file("src/main.jai", w); // this is asynchronous
  message_loop();
  compiler_end_intercept(w);

  print("\n------------\nBuilt '%'\n------------\n\n", EXECUTABLE_NAME);
  set_build_options_dc(.{do_output=false}); // don't generate an executable for build.jai
}

// @note: this is where we put any intercepts necessary
message_loop :: () {
  while true {
    message := compiler_wait_for_message();
    if message.kind == {
      case .COMPLETE;
        message_complete := cast(*Message_Complete) message;
        if message_complete.error_code != .NONE {
          print("Compilation failed with error code %\n", message_complete.error_code);
          exit(1);
        }
        break;
      case .PHASE;
        phase := cast(*Message_Phase) message;
        if phase.phase == .POST_WRITE_EXECUTABLE && phase.executable_write_failed {
          print("Failed to create executable '%'\n", phase.executable_name);
          exit(1);
        }
    }
  }
}

#run build();
