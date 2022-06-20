//===- LinalgFrontendInterfaces.td - Linalg Frontend Interfaces -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Linalg Frontend Interfaces
//
//===----------------------------------------------------------------------===//

#ifndef LINALG_FRONTEND_LINALGFRONTENDINTERFACES
#define LINALG_FRONTEND_LINALGFRONTENDINTERFACES

include "mlir/IR/OpBase.td"
include "mlir/Dialect/Linalg/IR/LinalgBase.td"

class Linalg_FrontendInterfaceBase<string interfaceName> : OpInterface<interfaceName> {
  let cppNamespace = "::mlir::linalg";
}

class Linalg_InstantiateOperatorOpInterface<
  string operatorCamelCase,
  string attrName,
  string defFloatOp = "",
  string defIntOp = "",
  string defComplexOp = ""> :
  Linalg_FrontendInterfaceBase<
    "Instantiate" # operatorCamelCase # "OperatorOpInterface">
{
  let description = [{
    Base class for all interfaces that allow for the instantiation of
    an arithmetic operator via an attribute.

    `operatorCamelCase` is supposed to be the name of the arithmetic
    operator in camel case, e.g., `Add` or `MaxUnsigned`.

    `attrName` specifies the name of the attribute that will be parsed
    into the name of the operation implementing the operator and an
    optional result type specified after a colon.

    `defIntOp`, `defFloatOp` and `defComplexOp` define the default
    operations that get instantiated if no value is provided in the
    attribute. All of `defIntOp`, `defFloatOp` and `DefComplexOp` may
    be omitted if there are no sensible default implementations.
  }];

  let extraClassDeclaration = [{
    static ::mlir::Value instantiateOperator(
       ::mlir::OpBuilder & builder,
       ::mlir::Location location,
       ::mlir::NamedAttrList attrs,
       ::mlir::ValueRange operands)
    {
      ::llvm::Optional<::mlir::NamedAttribute> attr =
          attrs.getNamed("}] # attrName # [{");

        // If attribute was not specified, fall back to default operation
        if(!attr.hasValue()) {
           if(::mlir::Value opr = Instantiate}] # operatorCamelCase # [{OperatorOpInterface::instantiateDefaultOperator(
             builder, location, operands)) {
               return opr;
           } else {
             ::mlir::emitError(
               location,
               "Could not generate default operation implementing "
               "operator }] # attrName # [{ for the given operands. "
               "Please specify an operation using the "
               "attribute '}] # attrName # [{'.");
             llvm_unreachable("");
           }
        }

        ::mlir::StringAttr strAttr =
              attr.getValue().getValue().dyn_cast<::mlir::StringAttr>();

        if (!attr) {
           ::mlir::emitError(
             location,
             "Attribute }] # attrName # [{ must be a string attribute.");
           llvm_unreachable("");
        }

        // Extract operation name and result type from specification
        std::pair<::llvm::StringRef, ::llvm::StringRef> spec =
          strAttr.strref().split(":");
        ::llvm::StringRef opName = std::get<0>(spec);
        ::llvm::StringRef resTypeName = std::get<1>(spec);

        ::mlir::Type resType;

        // Use type of LHS operand by default for the result type
        if(resTypeName.empty()) {
          if(operands.empty()) {
            ::mlir::emitError(location, "Missing result type for }] # attrName # [{ operator.");
            llvm_unreachable("");
          }

          resType = operands[0].getType();
        } else {
          resType = ::mlir::parseType(resTypeName, builder.getContext());

          if(!resType) {
            ::mlir::emitError(location, "Could not parse type '") << resTypeName << "'";
            llvm_unreachable("");
          }
        }

        ::mlir::OperationState state(location, opName, operands, resType, {});
        ::mlir::Operation *oprtr = builder.create(state);
        return oprtr->getResult(0);
    }

    static ::mlir::Value instantiateDefaultOperator(
       ::mlir::OpBuilder & builder,
       ::mlir::Location location,
       ::mlir::ValueRange operands)
    {
      const char* opName = nullptr;
      ::mlir::Type resType;

      }] #
      !if(!not(!empty(defFloatOp)), [{
        if(::llvm::all_of(operands, [](::mlir::Value v) {
          return v.getType().isa<::mlir::FloatType>();
        })) {
          opName = "}] # defFloatOp # [{";
          resType = operands[0].getType();
        }
      }], [{ }]) #
      !if(!not(!empty(defIntOp)), [{
        if(::llvm::all_of(operands, [](::mlir::Value v) {
          return v.getType().isa<::mlir::IntegerType>();
        })) {
          opName = "}] # defIntOp # [{";
          resType = operands[0].getType();
        }
      }], [{ }]) #
      !if(!not(!empty(defComplexOp)), [{
        if(::llvm::all_of(operands, [](::mlir::Value v) {
          return v.getType().isa<::mlir::ComplexType>();
        })) {
          opName = "}] # defComplexOp # [{";
          resType = operands[0].getType();
        }
      }], [{ }]) #
      [{

        if(opName != nullptr) {
          ::mlir::OperationState state(location, opName, operands, resType, {});
          ::mlir::Operation *oprtr = builder.create(state);
          return oprtr->getResult(0);
        }

      return ::mlir::Value();
    }

    static bool isOperatorInstance(::mlir::Operation &operation) {
    ::mlir::StringAttr strAttr =
          operation.template getAttrOfType<::mlir::StringAttr>("}] # attrName #  [{");

        if(strAttr) {
          // Attribute was specified: use operation from attribute
          std::pair<::llvm::StringRef, ::llvm::StringRef> spec =
            strAttr.strref().split(":");

          ::llvm::StringRef opName = std::get<0>(spec);

          return (operation.getName().getStringRef() == opName);
        }

        // Attribute was NOT specified: use default operations
      }] #
      !if(!not(!empty(defFloatOp)), [{
        if(operation.getName().getStringRef() == "}] # defFloatOp # [{")
          return true;
        }], [{ }]) #
      !if(!not(!empty(defIntOp)), [{
        if(operation.getName().getStringRef() == "}] # defIntOp # [{")
          return true;
        }], [{ }]) #
      !if(!not(!empty(defComplexOp)), [{
        if(operation.getName().getStringRef() == "}] # defComplexOp # [{")
          return true;
        }], [{ }]) #
      [{

        return false;
    }
    
    /// Returns a string containing the name of the operator for this
    /// instantiation interface
    static ::mlir::StringRef getOperatorName() {
      return "}] # operatorCamelCase # [{";
    }

    // /// Generic function name to instantiate the operator
    // static ::mlir::Value instantiateOperator(
    //     ::mlir::OpBuilder & builder,
    //     ::mlir::Location location,
    //     ::mlir::NamedAttrList attrs,
    //     ::mlir::ValueRange operands)
    // {
    //   return instantiate}] # operatorCamelCase # [{Operator(builder, location, attrs, operands);
    // }
  }];

  let methods = [
    InterfaceMethod<
      /*desc=*/"Checks if an operation is the " # attrName #
      " operator for this operation",
      /*retTy=*/"bool",
      /*methodName=*/"is" # operatorCamelCase # "Operator",
      /*args=*/(ins "::mlir::Operation &":$operation),
      /*methodBody=*/"",
      /*defaultImplementation=*/[{
        return Instantiate}] # operatorCamelCase # [{OperatorOpInterface::isOperatorInstance(operation);
      }]
    >,

    StaticInterfaceMethod<
      /*desc=*/"Instantiates the " # attrName # " operator in the absence of " #
      "an attribute specifying it",
      /*retTy=*/"::mlir::Value",
      /*methodName=*/"instantiateDefault" # operatorCamelCase # "Operator",
      /*args=*/(ins
        "::mlir::OpBuilder &":$builder,
        "::mlir::Location":$location,
        "::mlir::ValueRange":$operands),
      /*methodBody=*/"",
      /*defaultImplementation=*/[{
        return Instantiate}] # operatorCamelCase # [{OperatorOpInterface::instantiateDefaultOperator(builder, location, operands);
      }]
    >,

    StaticInterfaceMethod<
      /*desc=*/"Instantiates the " # attrName # " operator from the " #
      "attribute \"" # attrName # "\"",
      /*retTy=*/"::mlir::Value",
      /*methodName=*/"instantiate" # operatorCamelCase # "Operator",
      /*args=*/(ins
        "::mlir::OpBuilder &":$builder,
        "::mlir::Location":$location,
        "::mlir::NamedAttrList":$attrs,
        "::mlir::ValueRange":$operands),
      /*methodBody=*/[{}],
      /*defaultImplementation=*/[{
        return Instantiate}] # operatorCamelCase # [{OperatorOpInterface::instantiateOperator(builder, location, attrs, operands);
      }]
    >
  ];
}

// Create one interface for each common arithmetic operator
def Linalg_InstantiateAddOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Add", "add", "arith.addf", "arith.addi", "complex.add">;
def Linalg_InstantiateSubOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Sub", "sub", "arith.subf", "arith.subi", "complex.sub">;
def Linalg_InstantiateMulOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Mul", "mul", "arith.mulf", "arith.muli", "complex.mul">;
def Linalg_InstantiateMaxSignedOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"MaxSigned", "max_signed", "arith.maxf", "arith.maxsi">;
def Linalg_InstantiateMaxUnsignedOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"MaxUnsigned", "max_unsigned", "arith.maxf", "arith.maxui">;
def Linalg_InstantiateMinSignedOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"MinSigned", "min_signed", "arith.minf", "arith.minsi">;
def Linalg_InstantiateMinUnsignedOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"MinUnsigned", "min_unsigned", "arith.minf", "arith.minui">;

def Linalg_InstantiateExpOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Exp", "exp", "math.exp">;
def Linalg_InstantiateLogOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Log", "log", "math.log">;
def Linalg_InstantiateAbsOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Abs", "abs", "math.abs">;
def Linalg_InstantiateCeilOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Ceil", "ceil", "math.ceil">;
def Linalg_InstantiateFloorOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Floor", "floor", "math.floor">;
def Linalg_InstantiateNegfOperatorOpInterface :
  Linalg_InstantiateOperatorOpInterface<"Negf", "negf", "arith.negf">;

#endif // LINALG_FRONTEND_LINALGFRONTENDINTERFACES
