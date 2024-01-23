Matrix :: struct {
  m : int;
  n : int;
  array : [] f64;
}

operator * :: (a: Matrix, b: Matrix) -> Matrix {
  assert(a.n == b.m);
  c : Matrix = create(a.m, b.n);

  ai, _ := NewArray(a.n, f64, initialized=false,, temporary_allocator);
  for i : 0..a.m-1 {
    get_row(*a, ai, i);
    for j : 0..b.n-1 {
      bj := get_column_view(*b, j);
      cij := dot(ai, bj);
      set(*c, i, j, cij);
    }
  }
  return c;
}

dot :: (a: [] f64, b: [] f64) -> f64 {
  assert(a.count == b.count);
  result : f64 = 0;
  for i: 0..a.count-1 result += a[i] * b[i];
  return result;
}

// @note: COLUMN MAJOR FOR ALL FUNCTIONS AND PROCEDURES

create :: (m : int, n : int = -1) -> Matrix {
  mat : Matrix;
  mat.m = m;
  mat.n = ifx n == -1 then m else n;
  mat.array = NewArray(mat.m * mat.n, f64, true);
  return mat;
}

free :: (matrix : Matrix) {
  array_free(matrix.array);
}

zero :: inline (mat : *Matrix) {
  memset(mat.array.data, 0, size_of(f64)*mat.array.count);
}

get :: inline (mat : *Matrix, i : int, j : int) -> f64 #must {
  assert(i < mat.m);
  assert(j < mat.n);
  index := get_index(mat, i, j);
  return mat.array.data[index];
}

get_ptr :: inline (mat : *Matrix, i : int, j : int) -> *f64 #must {
  index := get_index(mat, i, j);
  return *mat.array.data[index];
}

set :: inline (mat : *Matrix, i : int, j : int, val : f64) {
  index := get_index(mat, i, j);
  mat.array.data[index] = val;
}

get_column :: inline (mat : *Matrix, output : [] f64, j : int, offset := 0) {
  assert(mat.m - offset > 0);
  assert(output.count >= mat.m - offset);
  memcpy(output.data, *mat.data[j*mat.m+offset], size_of(f64)*(mat.m-offset));
}

get_row :: inline (mat : *Matrix, output : [] f64, i : int, offset := 0) {
  assert(mat.n - offset > 0);
  assert(output.count >= mat.n - offset);
  for j : offset..mat.n-1 output[j-offset] = get(mat, i, j);
}

get_column_view :: (mat : *Matrix, j : int, offset := 0) -> [] f64 #must {
  output : [] f64;
  output.data = get_ptr(mat, offset, j);
  output.count = mat.m-offset;
  return output;
}

set_column :: (mat : *Matrix, column : [] f64, j : int, offset := 0) {
  assert(column.count >= mat.m);
  memcpy(*mat.array[j*mat.m+offset], column.data, size_of(f64)*(mat.m-offset));
}

set_row :: (mat : *Matrix, row : [] f64, i : int, offset := 0) {
  assert(row.count >= mat.n);
  for j : offset..mat.n-1 row[j-offset] = get(mat, i, j);
}

print_matrix :: (mat : *Matrix, log_level := Log_Level.NORMAL) {
  for i : 0..mat.m-1 {
    for j : 0..mat.n-1
      log("% ", formatFloat(get(mat, i, j), width=5, trailing_width=2, zero_removal=.YES, mode=.SHORTEST), log_level = log_level);
    log("\n", log_level=log_level);
  }
}

read_matrix :: (s_ : string) -> Matrix {
  s := String.trim(s_); // get rid of leading and trailing whitespace
  lines := String.split(s, cast(u8)(#char "\n"));
  m := lines.count; // assuming no empty lines
  n : int;
  matrix : Matrix = ---;
  for line_, i: lines {
    line := String.trim(line_);
    string_values := String.split(line, cast(u8)(#char " "));
    if i == 0 {
      n = string_values.count;
      matrix = create(m, n);
    }
    assert(string_values.count == n);

    for string_value, j : string_values {
      value := cast(f64) string_to_float(string_value);
      // cache unfriendly, but who cares
      set(*matrix, i, j, value);
    }
  }
  return matrix;
}

copy_over_diagonal :: (mat : *Matrix, $upper_right_to_lower_left := true) {
  assert(mat.m == mat.n); // not dealing with this shit
  if mat.m == 1 return;

  vec, _ := NewArray(mat.m, f64, initialized=false,, temporary_allocator);
  for i : 0..mat.n-2 {
    #if upper_right_to_lower_left {
        get_row(mat, vec, i, i);
        set_column(mat, vec, i, i);
    }
    else {
        get_column(mat, vec, i, i);
        set_row(mat, vec, i, i);
    }
  }
}


#scope_file

get_index :: inline (mat : *Matrix, i : int, j : int) -> int #must {
  return i + mat.m * j;
}

#import "util";
String :: #import "String";
