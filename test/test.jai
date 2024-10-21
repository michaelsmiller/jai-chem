// These are set by build.jai at compile time
#placeholder TESTS; // [] TestResult
#placeholder RETURN_ON_FAIL; // bool

// Needed to return immediately
#add_context return_on_fail := false;
#add_context skip_all_remaining_tests := false;

TestSignature :: #type ();
TestInfo :: struct {
  func : TestSignature;
  is_run := true;
}


main :: () {
  repeat :: (n : int, s : string) -> string {
    builder: String_Builder;
    builder.allocator = temp;
    for 1..n print_to_builder(*builder, s);
    return builder_to_string(*builder);
  }

  print_header :: (messages: [] string, colors: [] Console_Color, color := Console_Color.WHITE) {
    assert(colors.count == messages.count);
    total_message_size := 0;
    for messages total_message_size += it.count;

    left_filler, right_filler : int;
    if total_message_size < CONSOLE_WIDTH {
      total_filler := CONSOLE_WIDTH - total_message_size;
      left_filler = total_filler / 2;
      right_filler = total_filler - left_filler;
    }

    for 1..left_filler print_color("=", color=color);
    for message, i : messages {
      print_color(message, color=colors[i]);
    }
    for 1..right_filler print_color("=", color=color);
    print("\n");
  }

  print_header :: (messages: [] string, color := Console_Color.WHITE) {
    colors : [..] Console_Color;
    defer array_free(colors);
    for messages array_add(*colors, color);
    print_header(messages, colors, color=color);
  }

  print_header :: (message : string, color := Console_Color.WHITE) {
    messages : [1] string = string.[message];
    print_header(messages, color=color);
  }

  skipped_test_count := 0;
  for *TESTS if !it.is_run skipped_test_count += 1;
  unskipped_test_count := TESTS.count - skipped_test_count;
  header_message := tprint(" Running % tests ", unskipped_test_count);
  print_header(header_message);
  print("\n");

  failed_checks : [..] TestResult;
  defer array_free(failed_checks);

  // Actually run the tests
  failed_functions : Table(string, bool) = ---;
  init(*failed_functions, slots_to_allocate=unskipped_test_count);
  defer deinit(*failed_functions);

  my_logger :: (message: string, data: *void, info: Log_Info) {
    log_level := Log_Level.NORMAL;
    if info.common_flags & Log_Flags.VERBOSE_ONLY log_level = .VERBOSE;
    else if info.common_flags & Log_Flags.VERY_VERBOSE_ONLY log_level = .VERY_VERBOSE;

    if context.log_level < log_level return;
    print(message);
  }

  // context is important
  context.logger = my_logger;
  context.log_level = Log_Level.NORMAL;
  context.return_on_fail = RETURN_ON_FAIL;
  start_time := current_time_monotonic();
  for test_info: TESTS if test_info.is_run {
    test_info.func();
    if context.skip_all_remaining_tests
      break;
  }
  end_time := current_time_monotonic();
  duration_milliseconds := to_milliseconds(end_time - start_time);

  for result: all_test_results {
    if !result.passed {
      array_add(*failed_checks, result);
      table_set(*failed_functions, result.function_name, true);
    }
  }

  print("\n");

  num_failed_tests := failed_functions.count;
  num_passed_tests := unskipped_test_count - num_failed_tests;
  num_color : Console_Color = ifx num_failed_tests > 0 then .RED else .GREEN;
  header_messages : [..] string;
  header_colors : [..] Console_Color;
  defer array_free(header_messages);
  defer array_free(header_colors);
  if num_failed_tests > 0 {
    failures_message := tprint(" % failed", num_failed_tests);
    array_add(*header_messages, failures_message);
    array_add(*header_messages, ",");
    array_add(*header_colors, .RED);
    array_add(*header_colors, .WHITE);
  }
  passed_message := tprint(" % passed", num_passed_tests);
  array_add(*header_messages, passed_message);
  array_add(*header_colors, .CYAN);
  if skipped_test_count > 0 {
    message := tprint("% skipped", skipped_test_count);
    array_add(*header_messages, ", ");
    array_add(*header_colors, .WHITE);
    array_add(*header_messages, message);
    array_add(*header_colors, .YELLOW);
  }

  {
    message := tprint("in % s", cast(float)duration_milliseconds * 0.001);
    array_add(*header_messages, ", ");
    array_add(*header_colors, .WHITE);
    array_add(*header_messages, message);
    array_add(*header_colors, num_color);
  }

  array_add(*header_messages, " ");
  array_add(*header_colors, .WHITE);
  print_header(header_messages, header_colors, color=num_color);

  if num_failed_tests == 0 return;

  for result, i : failed_checks {
    location := tprint("%:%", result.location.fully_pathed_filename, result.location.line_number);
    print("Test: %\nCheck: %\n%\n\n", result.function_name, location, result.message);
    print_header("");
  }
}

// This can only run once the metaprogram finds all the tests
// and fills out the TESTS datastructure
#run main();


#scope_file

#import "test_suite";
#import "check"; // for TestResult

#import "Basic";
#import "Print_Color";
#import "Hash_Table";
