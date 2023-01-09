error :: (message : string, print_args : ..Any) #expand {
  log("ERROR (%): ", #procedure_name(), type=.ERROR);
  log(message, ..print_args, type=.ERROR);
  exit(1);
}

LogType :: enum u32 {
  NORMAL :: 0;
  TITLE;
  WARNING;
  ERROR;
  SUCCESS;
}

LoggerData :: struct {
  file : File;
}

file_logger :: (msg: string, data : *void, info: Log_Info) {
  logger_data := cast(*LoggerData)data;
  assert(is_valid(logger_data.file));
  success := file_write(*logger_data.file, msg);
  assert(success);
}

color_logger :: (msg : string, data : *void, info: Log_Info) {
  file_logger(msg, data, info); // always log to a file as well
  if info.common_flags & .TO_FILE_ONLY
    return;

  color : Console_Color;
  log_type := cast(LogType)info.user_flags;
  if #complete log_type == {
    case .NORMAL; color = .WHITE;
    case .TITLE; color = .BLUE;
    case .WARNING; color = .YELLOW;
    case .ERROR; color = .RED;
    case .SUCCESS; color = .GREEN;
  }

  if (info.common_flags & (.VERBOSE_ONLY | Log_Flags.VERY_VERBOSE_ONLY)) && context.log_level < .VERBOSE return;
  if (info.common_flags & .VERY_VERBOSE_ONLY) && context.log_level < .VERY_VERBOSE return;

  print_color(msg, color=color, to_standard_error = log_type == .ERROR);
}

log :: inline (format_string: string, args : .. Any, loc := #caller_location, flags := Log_Flags.NONE, type := LogType.NORMAL) {
  log(format_string, ..args, loc=loc, flags=flags, user_flags=cast(u32)type);
}

#scope_file

#import "Basic";
#import "File";
String :: #import "String";
#import "Print_Color";
