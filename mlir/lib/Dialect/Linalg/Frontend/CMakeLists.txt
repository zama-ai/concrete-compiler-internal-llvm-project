add_mlir_dialect_library(MLIRLinalgFrontend
  LinalgFrontendInterfaces.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/Linalg

  LINK_LIBS PUBLIC
  MLIRIR
)
