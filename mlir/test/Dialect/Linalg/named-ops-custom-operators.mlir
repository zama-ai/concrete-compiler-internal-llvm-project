// RUN: mlir-opt -split-input-file -verify-diagnostics %s | FileCheck %s

// Specify matrix multiplication on float, integer, index and complex
// values using attributes for the add and mul operator.

// CHECK-LABEL: func @matmul_float
func.func @matmul_float(%arg0: memref<2x2xf32>, %arg1: memref<2x2xf32>, %output: memref<2x2xf32>) -> () {
  linalg.matmul { add = "arith.addf", mul = "arith.mulf" }
    ins(%arg0, %arg1: memref<2x2xf32>,
                      memref<2x2xf32>)
   outs(%output: memref<2x2xf32>)
  return
}

// -----

// CHECK-LABEL: func @matmul_int
func.func @matmul_int(%arg0: memref<2x2xi32>, %arg1: memref<2x2xi32>, %output: memref<2x2xi32>) -> () {
  linalg.matmul { add = "arith.addi", mul = "arith.muli" }
    ins(%arg0, %arg1: memref<2x2xi32>,
                      memref<2x2xi32>)
   outs(%output: memref<2x2xi32>)
  return
}

// -----

// CHECK-LABEL: func @matmul_index
func.func @matmul_index(%arg0: memref<2x2xindex>, %arg1: memref<2x2xindex>, %output: memref<2x2xindex>) -> () {
  linalg.matmul { add = "arith.addi", mul = "arith.muli" }
    ins(%arg0, %arg1: memref<2x2xindex>,
                      memref<2x2xindex>)
   outs(%output: memref<2x2xindex>)
  return
}

// -----

// CHECK-LABEL: func @matmul_complex
func.func @matmul_complex(%arg0: memref<2x2xcomplex<f32>>, %arg1: memref<2x2xcomplex<f32>>, %output: memref<2x2xcomplex<f32>>) -> () {
  linalg.matmul { add = "complex.add", mul = "complex.mul" }
    ins(%arg0, %arg1: memref<2x2xcomplex<f32>>,
                      memref<2x2xcomplex<f32>>)
   outs(%output: memref<2x2xcomplex<f32>>)
  return
}
