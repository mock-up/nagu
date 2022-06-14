## src/nagu/program.nim defines the ProgramObject type and procedures related to its for abstracting OpenGL program.

from nimgl/opengl import nil
from shader import ShaderObject, id, ShaderObjectKind, convertGLExpression
from opengl as naguOpengl import OpenGLDefect
from std/tables import Table, initTable, len, `[]`, `[]=`
from std/strformat import `&`
import utils, vbo

type
  ProgramVariableKind* = enum
    pvkAttrib,
    pvkUniform,
    pvkSubroutineUniform

  ProgramObjectObj = object
    id: opengl.GLuint
    linked: bool
    nameToIndex*: Table[string, tuple[index: int, kind: ProgramVariableKind]]
  
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
  
  ProgramNotExistsActiveSubroutineUniformDefect* = object of ProgramDefect

  mvpMatrix* = array[16, float32]
    ## Represents model view projection matrixes.

func identityMatrix*: mvpMatrix = [
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
    nameToIndex: initTable[string, (int, ProgramVariableKind)]()
  )

func id* (program: ProgramObject): opengl.GLuint =
  ## Gets id of `program`.
  result = program.id

func linked* (program: ProgramObject): bool =
  ## Gets `program` linked or not.
  result = program.linked

func index* (program: ProgramObject, name: string): int =
  ## Queries `program` for `name` and corresponding index.
  result = program.nameToIndex[name].index

proc attach* (program: ProgramObject, shader: ShaderObject): ProgramObject =
  ## Attach `shader` to `program`.
  result = program
  debugOpenGLStatement:
    echo &"glAttachShader({program.id}, {shader.id})"
  opengl.glAttachShader(program.id, opengl.GLuint(shader.id))

proc successLink (program: ProgramObject): bool =
  var status: opengl.GLint
  opengl.glGetProgramiv(program.id, opengl.GL_LINK_STATUS, status.addr)
  debugOpenGLStatement:
    echo &"glGetProgramiv({program.id}, GL_LINK_STATUS, {status})"
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
    debugOpenGLStatement:
      echo &"glUseProgram({program.id})"
    opengl.glUseProgram(program.id)

proc link* (program: var ProgramObject) =
  ## Links `program`.
  debugOpenGLStatement:
    echo &"glLinkProgram({program.id})"
  opengl.glLinkProgram(program.id)
  if program.successLink:
    program.linked = true
  else:
    raise newException(ProgramLinkingDefect, "Failed to link shader program: " & program.log)

proc registerAttrib* (program: var ProgramObject, name: string) =
  ## Register an attrib variable named `name` in `program`
  let index = program.nameToIndex.len
  program.nameToIndex[name] = (index, pvkAttrib)
  debugOpenGLStatement:
    echo &"glBindAttribLocation({program.id}, {index}, {name})"
  opengl.glBindAttribLocation(program.id, opengl.GLuint(index), name)

proc registerUniform* (program: var ProgramObject, name: string) =
  ## Register a uniform variable named `name` in `program`
  let index = opengl.glGetUniformLocation(program.id, name).int
  if index == -1:
    raise newException(ProgramNotExistsActiveUniformDefect, &"Active Uniform variable {name} does not exist in GLSL.")
  program.nameToIndex[name] = (index, pvkUniform)

proc registerSubroutineUniform* (program: var ProgramObject, shaderType: ShaderObjectKind, name: string) =
  let index = opengl.glGetSubroutineUniformLocation(program.id, shaderType.convertGLExpression, name).int
  if index == -1:
    raise newException(ProgramNotExistsActiveSubroutineUniformDefect, &"Active Subroutine-Uniform variable {name} does not exist in GLSL.")
  program.nameToIndex[name] = (index, pvkSubroutineUniform)

proc make* (_: typedesc[ProgramObject], vertex_shader: ShaderObject, fragment_shader: ShaderObject): ProgramObject =
  ## Makes a program linking `vertex_shader` and `fragment_shader`.
  result = ProgramObject
            .init()
            .attach(vertex_shader)
            .attach(fragment_shader)
  result.link()
  result.use()

proc make* (_: typedesc[ProgramObject], vertex_shader: ShaderObject, fragment_shader: ShaderObject, attributes: seq[string] = @[], uniforms: seq[string] = @[], subroutine_uniforms: seq[(ShaderObjectKind, string)] = @[]): ProgramObject =
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
  for (shader_kind, subroutine_uniform) in subroutine_uniforms:
    result.registerSubroutineUniform(shader_kind, subroutine_uniform)

proc `[]`* (program: ProgramObject, name: string): int =
  result = program.nameToIndex[name].index

proc `[]=`* (program: ProgramObject, name: string, v1: int) =
  let index = program[name]
  opengl.glUniform1i(opengl.GLint(index), opengl.GLint(v1))

  debugOpenGLStatement:
    echo &"glUniform1i({index}, {v1})"

proc `[]=`* (program: ProgramObject, name: string, matrix4v: array[16, float32]) =
  let index = program[name]
  var matrix4v = matrix4v
  opengl.glUniformMatrix4fv(opengl.GLint(index), 1, opengl.GLboolean(false), matrix4v[0].addr)
  
  debugOpenGLStatement:
    echo &"glUniformMatrix4fv(index, 1, false, {matrix4v})"

proc `[]=`* [I: static int, T] (program: ProgramObject, name: string, data: tuple[vbo: BindedVBO[I ,T], size: int]) =
  let index = opengl.GLuint(program[name])
  opengl.glEnableVertexAttribArray(index)
  opengl.glVertexAttribPointer(index, opengl.GLint(data.size), opengl.EGL_FLOAT, false, opengl.GLSizei(data.vbo.data.len), cast[pointer](0))
