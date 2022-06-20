//===- LinalgFrontendOpInterfaces.h - Linalg frontend op interfaces -------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the frontend operation interfaces for Linalg
// operations.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LINALG_FRONTEND_LINALGFRONTENDINTERFACES_H_
#define MLIR_DIALECT_LINALG_FRONTEND_LINALGFRONTENDINTERFACES_H_

#include "mlir/AsmParser/AsmParser.h"
#include "mlir/Dialect/Complex/IR/Complex.h"
#include "mlir/IR/Builders.h"

/// Include the generated interface declarations.
#include "mlir/Dialect/Linalg/Frontend/LinalgFrontendOpInterfaces.h.inc"

#endif // MLIR_DIALECT_LINALG_FRONTEND_LINALGFRONTENDINTERFACES_H_
