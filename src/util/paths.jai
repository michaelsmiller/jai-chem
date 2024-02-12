SRC_DIR :: #run get_parent_directory(#filepath);
BASE_DIR :: #run get_parent_directory(SRC_DIR);
// GEOMETRY_DIR :: #run sprint("%geometry/", BASE_DIR);
BASIS_DIR :: #run sprint("%basis/", BASE_DIR);

#scope_file

get_parent_directory :: (dir0 : string) -> string {
  dir := String.trim_right(dir0, "/");
  i := String.find_index_from_right(dir, cast(u8)(#char "/"));
  has_slash := i != -1;
  if !has_slash
    return sprint("%/../", dir);
  success, parent, extra := String.split_from_right(dir, cast(u8)(#char "/"));
  assert(success);
  return sprint("%/", parent);
}

String :: #import "String";
