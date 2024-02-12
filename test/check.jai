// global

CONSOLE_WIDTH :: 110;
DETAIL_WIDTH :: 60;
NAME_WIDTH :: 30;

all_test_results : [..] TestResult;

TestResult :: struct {
  passed : bool = true;
  function_name : string = "";
  message : string = "";
  location: Source_Code_Location;
}

// This should be called at the beginning of every test
test_print:: (message : string) #expand {
  func_name := #procedure_name(#this);

  conform_to_column_width :: (input: string, width: int) -> string {
    builder: String_Builder;

    end := Math.Min(width, input.count);
    if input.count <= end {
      print_to_builder(*builder, input);
      space :: " ";
      for input.count..width-1 print_to_builder(*builder, space);
    }
    else {
      print_to_builder(*builder, String.slice(input, 0, end-3));
      dot :: ".";
      for end-3..width-1 print_to_builder(*builder, dot);
    }

    return builder_to_string(*builder);
  }

  // total_message := tprint("% (%)");
  func_name_message := tprint("%()", func_name);
  column1 := conform_to_column_width(func_name_message, NAME_WIDTH,, temp);
  column2 := conform_to_column_width(message, DETAIL_WIDTH,, temp);
  print_color(column1, color=.WHITE);
  print_color(column2, color=.WHITE);
  `defer print("\n"); // after all the P and F get printed, next line
}

check :: (
  condition : bool,
  message : string = "Test Failed",
  location:=#caller_location,
  print_on_success := true
) #expand {
  result := array_add(*all_test_results);
  result.passed = condition;
  result.message = message;
  result.location = location;
  result.function_name = #procedure_name(#this);

  if !condition
    print_color("F", color=.RED);
  else if condition && print_on_success
    print_color(".", color=.GREEN);

  // @todo: turn this on based on a command line flag
  if context.return_on_fail && !condition {
    context.skip_all_remaining_tests = true;
    `return; // no more checks needed since this one failed
  }
}

check_eq_fancy :: (
  a : Code,
  b : Code,
  location := #caller_location
) #expand {
  // Needed the "stallable"s here because compiler thinks there might be a dependency loop
  // otherwise.
  a_string := #run,stallable code_to_string(a);
  b_string := #run,stallable code_to_string(b);
  a_var := #insert a;
  b_var := #insert b;
  message := tprint("% != % (left: %, right: %)", a_string, b_string, a_var, b_var);
  check(a_var == b_var, message=message, location=location);
}

check_compare :: (
  a : $T,
  b : T,
  operation : #type (a : T, b : T) -> bool,
  failed_expression_template := "op(%0, %1) is false",
  location := #caller_location,
  print_on_success := true
) #expand {
  condition := operation(a, b);
  message := tprint(failed_expression_template, a, b);
  check(condition, message=message, location=location, print_on_success=print_on_success);
}

check_eq :: (
  a : $T,
  b : T,
  location := #caller_location,
  print_on_success := true
) #expand {
  operation :: (a : T, b : T) -> bool {return a == b;};
  check_compare(a, b, location=location, operation=operation, failed_expression_template="% != %", print_on_success=print_on_success);
}

check_close :: (a : float64, b : float64, epsilon : float64 = 1.0E-10, location:=#caller_location) #expand {
  diff := Math.abs(a - b);
  condition := diff < epsilon;
  message := tprint("% != % (|x - y| > %)", a, b, formatFloat(epsilon, mode=.SCIENTIFIC));
  check(condition, message, location=location);
}

#scope_file

code_to_string :: (code: Code) -> string #expand {
  // from  @farzher on Discord
  ProgramPrint       :: #import "Program_Print";
  code_node := Compiler.compiler_get_nodes(code);
  builder: String_Builder;
  ProgramPrint.print_expression(*builder, code_node);
  return builder_to_string(*builder,, allocator=temp);
}

#import "Basic";
Compiler :: #import "Compiler";
#import "Print_Color";
#import "Hash_Table";
Math :: #import "Math";
String :: #import "String";

