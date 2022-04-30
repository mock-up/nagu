## src/nagu/vao.nim defines the VAO type and procedures related to its for abstracting OpenGL VAO.

from nimgl/opengl import nil

type
  vaoObj = object
    id: opengl.GLuint
  
  VAO* = ref vaoObj
    ## The ProgramObject type representations OpenGL program object.

proc init (_: typedesc[VAO]): VAO =
  result = VAO()
  opengl.glGenVertexArrays(1, result.id.addr)

proc attention (vao: VAO) =
  opengl.glBindVertexArray(vao.id)

proc make* (_: typedesc[VAO]): VAO =
  ## Initializes and binds VAO.
  result = VAO.init()
  result.attention()

proc draw* (vao: VAO) =
  ## Draws from `vao`.
  vao.attention()
  opengl.glDrawArrays(opengl.GL_TRIANGLES, 0, 3)
