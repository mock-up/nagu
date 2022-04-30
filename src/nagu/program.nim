## src/nagu/program.nim defines the ProgramObject type and procedures related to its for abstracting OpenGL program.

from nimgl/opengl import nil
from shader import ShaderObject, id
from opengl as naguOpengl import OpenGLDefect
from std/tables import Table, initTable, len, `[]`, `[]=`
from std/strformat import `&`

type
  ProgramObjectObj = object
    id: opengl.GLuint
    linked: bool
    nameToIndex: Table[string, int]
  
  ProgramObject* = ref ProgramObjectObj
    ## The ProgramObject type representations OpenGL program object.

  ProgramDefect* = object of OpenGLDefect
    ## Raised by something with OpenGL programs.

  ProgramCreationDefect* = object of ProgramDefect
    ## Raised by creating OpenGL programs.

  ProgramLinkingDefect* = object of ProgramDefect
    ## Raised by linking OpenGL programs.

  ProgramNotExistsActiveUniformDefect* = object of ProgramDefect
    ## Raised by the condition that program don't have active uniform variables.

  mvpMatrix* = array[16, float32]
    ## Represents model view projection matrixes.

const IdentityMatrix*: mvpMatrix = [
  1.0'f, 0.0, 0.0, 0.0,
  0.0,   1.0, 0.0, 0.0,
  0.0,   0.0, 1.0, 0.0,
  0.0,   0.0, 0.0, 1.0
]
  ## Matrix which value does not change when applied.

proc init* (_: typedesc[ProgramObject]): ProgramObject =
  ## Initializes ProgramObject.
  let program = opengl.glCreateProgram()
  if program == opengl.GLuint(0):
    raise newException(ProgramCreationDefect, "Failed to create the program for some reason.")
  result = ProgramObject(
    id: program,
    linked: false,
    nameToIndex: initTable[string, int]()
  )

func id* (program: ProgramObject): opengl.GLuint =
  ## Gets id of `program`.
  result = program.id

func linked* (program: ProgramObject): bool =
  ## Gets `program` linked or not.
  result = program.linked

func index* (program: ProgramObject, name: string): int =
  ## Queries `program` for `name` and corresponding index.
  result = program.nameToIndex[name]

proc attach* (program: ProgramObject, shader: ShaderObject): ProgramObject =
  ## Attach `shader` to `program`.
  result = program
  opengl.glAttachShader(program.id, opengl.GLuint(shader.id))

proc successLink (program: ProgramObject): bool =
  var status: opengl.GLint
  opengl.glGetProgramiv(program.id, opengl.GL_LINK_STATUS, status.addr)
  result = status == opengl.GLint(opengl.GL_TRUE)

proc log* (program: ProgramObject): string =
  ## Gets logs about OpenGL programs.
  var log_length: opengl.GLint
  opengl.glGetProgramiv(program.id, opengl.GL_INFO_LOG_LENGTH, log_length.addr)
  if log_length.int > 0:
    var
      log: cstring
      written_length: opengl.GLsizei
    opengl.glGetProgramInfoLog(program.id, log_length, written_length.addr, log)
    result = $log

proc use* (program: ProgramObject) =
  ## Use `program` if it is linked.
  if program.linked:
    opengl.glUseProgram(program.id)

proc link* (program: var ProgramObject) =
  ## Links `program`.
  opengl.glLinkProgram(program.id)
  if program.successLink:
    program.linked = true
  else:
    raise newException(ProgramLinkingDefect, "Failed to link shader program: " & program.log)

proc registerAttrib* (program: var ProgramObject, name: string) =
  ## Register an attrib variable named `name` in `program`
  let index = program.nameToIndex.len
  program.nameToIndex[name] = index
  opengl.glBindAttribLocation(program.id, opengl.GLuint(index), name)

proc registerUniform* (program: var ProgramObject, name: string) =
  ## Register a uniform variable named `name` in `program`
  let index = opengl.glGetUniformLocation(program.id, name).int
  if index == -1:
    raise newException(ProgramNotExistsActiveUniformDefect, &"Active Uniform variable {name} does not exist in GLSL.")
  program.nameToIndex[name] = index

proc make* (_: typedesc[ProgramObject], vertex_shader: ShaderObject, fragment_shader: ShaderObject): ProgramObject =
  ## Makes a program linking `vertex_shader` and `fragment_shader`.
  result = ProgramObject
            .init()
            .attach(vertex_shader)
            .attach(fragment_shader)
  result.link()
  result.use()

proc make* (_: typedesc[ProgramObject], vertex_shader: ShaderObject, fragment_shader: ShaderObject, attributes, uniforms: seq[string]): ProgramObject =
  ## Makes a program linking `vertex_shader` and `fragment_shader`; registering `attributes` and `uniforms`.
  result = ProgramObject
            .init()
            .attach(vertex_shader)
            .attach(fragment_shader)
  for attribute in attributes:
    result.registerAttrib(attribute)
  result.link()
  result.use()
  for uniform in uniforms:
    result.registerUniform(uniform)

proc applyMatrix* (program: ProgramObject, name: string, matrix: mvpMatrix = IdentityMatrix) =
  ## Apply matrix by passing `matrix` to the `name` variable.
  var matrix = matrix
  let index = opengl.GLint(program.nameToIndex[name])
  opengl.glUniformMatrix4fv(index, 1, opengl.GLboolean(false), matrix[0].addr)
