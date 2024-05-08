// @note: COLUMN MAJOR FOR ALL FUNCTIONS AND PROCEDURES

Matrix :: struct {
  array : [] f64;
  m : int;
  n : int;
}

// matrix multiplication
operator * :: (a: Matrix, b: Matrix) -> Matrix {
  assert(a.n == b.m);
  c : Matrix = create(a.m, b.n);

  for i : 0..a.m-1 {
    ai := get_row(*a, i);
    for j : 0..b.n-1 {
      bj := get_column(*b, j);
      cij := dot(ai, bj);
      set(*c, i, j, cij);
    }
  }
  return c;
}

create :: (m : int, n : int = -1) -> Matrix #must {
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

get_column :: inline (mat: *Matrix, j: int, offset := 0) -> VecSlice #must {
  start := get_ptr(mat, offset, j);
  v := VecSlice.{mat.m-offset, 1, start};
  return v;
}

get_row :: inline (mat: *Matrix, i: int, offset := 0) -> VecSlice #must {
  start := get_ptr(mat, i, offset);
  v := VecSlice.{mat.n-offset, mat.m, start};
  return v;
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
      value := cast(f64) string_to_float64(string_value);
      // cache unfriendly, but who cares
      set(*matrix, i, j, value);
    }
  }
  return matrix;
}

copy_over_diagonal :: (mat : *Matrix, $upper_right_to_lower_left := true) {
  assert(mat.m == mat.n); // not dealing with this shit
  if mat.m == 1 return;

  for i : 0..mat.n-2 {
    row := get_row(mat, vec, i, i+1);
    col := get_column(mat, vec, i, i+1);
    #if upper_right_to_lower_left
      copy(row, col); // copy ith row past diagonal to ith column past diagonal
    else
      copy(col, row); // copy ith column past diagonal to ith row past diagonal
  }
}


#scope_file

get_index :: inline (mat : *Matrix, i : int, j : int) -> int #must {
  return i + mat.m * j;
}

#import,file "vector.jai";
#import "util";
String :: #import "String";
