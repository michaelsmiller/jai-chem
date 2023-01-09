Matrix :: struct {
  m : int;
  n : int;
  array : [] f64;
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
  output.array.count = mat.m-offset;
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

copy_over_diagonal :: (mat : *Matrix, $upper_right_to_lower_left := true) {
  assert(mat.m == mat.n); // not dealing with this shit
  if mat.m == 1 return;

  vec, _ := NewArray(mat.m, f64, initialized=false, allocator=temporary_allocator);
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
