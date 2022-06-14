import vbo

type
  ModelMatrixVector* = VBO[16, float32]
  BindedModelMatrixVector* = BindedVBO[16, float32]

  ModelMatrix* = array[4, ModelMatrixVector]

proc init* (_: typedesc[ModelMatrix]): ModelMatrix =
  result = [
    ModelMatrixVector.init(),
    ModelMatrixVector.init(),
    ModelMatrixVector.init(),
    ModelMatrixVector.init()
  ]
