TestArguments :: struct {
  test : bool = false;
  substring : string = "";
  return_on_fail: bool = false;
}

build :: () {
    options := get_build_options();
    raw_args := options.compile_time_command_line;

    _, args, set_args, _ := parse_arguments(TestArguments, args=raw_args, flags=Default_Argument_Flags & .SHOW_HELP_ON_ERROR);

    // Create a workspace for the target program.
    w := compiler_create_workspace("Target Program");
    assert(cast(bool)w);

    target_options := get_build_options(w);
    target_options.backend = .X64;

    import_path : [..] string;
    defer array_free(import_path);
    array_add(*import_path, ..target_options.import_path);
    array_add(*import_path, "modules");
    array_add(*import_path, "src");
    main_filepath : string;
    if args.test {
      main_filepath = tprint("%/test/test.jai", #filepath);
      array_add(*import_path, "test");
      target_options.output_type = .NO_OUTPUT;
    }
    else {
      target_options.output_executable_name = "main";
      main_filepath = tprint("%/src/main.jai", #filepath);
    }

    // Add local modules/ path to import_paths
    target_options.import_path = import_path;
    set_build_options(target_options, w);

    if args.test {
      compiler_begin_intercept(w, .SKIP_EXPRESSIONS_WITHOUT_NOTES);
      add_build_file(main_filepath, w);
      message_loop(args, set_args);
      compiler_end_intercept(w);
    }
    else {
      add_build_file(main_filepath, w);
      print("\nDone!\n\n");
    }

    // This metaprogram should not generate any output executable:
    set_build_options_dc(.{do_output=false});
}

#run build();

TEST_INFO_TEMPLATE :: #string DONE
  TestInfo.{func=%, is_run=%}
DONE

message_loop :: (args: TestArguments, set_args: Is_Set(TestArguments)) {
  inserted_run := false;
  test_info_strings : [..] string;
  while true {
    message := compiler_wait_for_message();
    if message.kind == {
      case .TYPECHECKED;
        // Look for any procedure that has been typechecked. If it is
        // a procedure we want to run, make note of it for later.
        typechecked := cast(*Message_Typechecked) message;
        for tc: typechecked.procedure_headers {
          header := tc.expression;

          if has_note(header, "Test") {
            ignored := set_args.substring && !String.contains_nocase(header.name, args.substring);
            test_info_string := tprint(TEST_INFO_TEMPLATE, header.name, !ignored);
            array_add(*test_info_strings, test_info_string);
          }
        }

      case .PHASE;
        phase := cast(*Message_Phase) message;
        if phase.phase == .TYPECHECKED_ALL_WE_CAN  && !inserted_run {
          inserted_run = true; // so that this only happens once
          test_infos_string := String.join(..test_info_strings, ",");
          s := tprint("TESTS :: #run TestInfo.[%];", test_infos_string);
          add_build_string(s, message.workspace);

          // args.return_on_fail
          s = tprint("RETURN_ON_FAIL :: %;", args.return_on_fail);
          add_build_string(s, message.workspace);
        }
      case .COMPLETE;
        break;
    }
  }
}

has_note :: (header: *Code_Procedure_Header, note: string) -> bool {
  for header.notes  if it.text == note  return true;
  return false;
}

#scope_file

#import "Basic";
#import "Compiler";
String :: #import "String";
#import "Command_Line_Args";
