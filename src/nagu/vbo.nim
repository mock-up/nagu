from nimgl/opengl import nil
import program
import strformat

type
  VBOObj [binded: static bool, I: static int, T] = object
    id: opengl.GLuint
    target: VBOTarget
    data: array[I, T]
    usage: VBOUsage

  VBO* [I: static int, T] = ref VBOObj[false, I, T]
  BindedVBO* [I: static int, T] = ref VBOObj[true, I, T]

  VBOTarget* = enum
    vtArrayBuffer = opengl.GL_ARRAY_BUFFER
    vtElementArrayBuffer = opengl.GL_ELEMENT_ARRAY_BUFFER
    vtPixelPackBuffer = opengl.GL_PIXEL_PACK_BUFFER
    vtPixelUnpackBuffer = opengl.GL_PIXEL_UNPACK_BUFFER
    vtUniformBuffer = opengl.GL_UNIFORM_BUFFER
    vtTextureBuffer = opengl.GL_TEXTURE_BUFFER
    vtTransformFeedbackBuffer = opengl.GL_TRANSFORM_FEEDBACK_BUFFER
    vtCopyReadBuffer = opengl.GL_COPY_READ_BUFFER
    vtCopyWriteBuffer = opengl.GL_COPY_WRITE_BUFFER
    vtDrawIndirectBuffer = opengl.GL_DRAW_INDIRECT_BUFFER
    vtShaderStorageBuffer = opengl.GL_SHADER_STORAGE_BUFFER
    vtDispatchIndirectBuffer = opengl.GL_DISPATCH_INDIRECT_BUFFER
    vtQueryBuffer = opengl.GL_QUERY_BUFFER
    vtAtomicCounterBuffer = opengl.GL_ATOMIC_COUNTER_BUFFER
  
  VBOUsage* = enum
    vuStreamDraw = opengl.GL_STREAM_DRAW
    vuStreamRead = opengl.GL_STREAM_READ
    vuStreamCopy = opengl.GL_STREAM_COPY
    vuStaticDraw = opengl.GL_STATIC_DRAW
    vuStaticRead = opengl.GL_STATIC_READ
    vuStaticCopy = opengl.GL_STATIC_COPY
    vuDynamicDraw = opengl.GL_DYNAMIC_DRAW
    vuDynamicRead = opengl.GL_DYNAMIC_READ
    vuDynamicCopy = opengl.GL_DYNAMIC_COPY

proc `target=`* [I: static int, T] (vbo: var BindedVBO[I, T], target: VBOTarget) =
  vbo.target = target

proc `data=`* [I: static int, T] (vbo: var BindedVBO[I, T], data: array[I, T]) =
  let size = cint(sizeof(vbo.data))
  vbo.data = data
  opengl.glBufferData(
    opengl.GLenum(vbo.target),
    size,
    vbo.data[0].addr,
    opengl.GLenum(vbo.usage)
  )
  when defined(debuggingOpenGL):
    echo &"glBufferData({vbo.target}, {size}, data[0].addr, {vbo.usage})"

proc `usage=`* [I: static int, T] (vbo: var BindedVBO[I, T], usage: VBOUsage) =
  vbo.usage = usage

proc init* [I: static int, T] (_: typedesc[VBO[I, T]]): VBO[I, T] =
  var data: array[I, T]
  result = VBO[I, T](target: vtArrayBuffer, usage: vuStaticDraw, data: data)
  when defined(debuggingOpenGL):
    echo &"glGenBuffers(1, result.id.addr)"
  opengl.glGenBuffers(1, result.id.addr)

func id* [B: static bool, I: static int, T] (vbo: VBOObj[B, I, T]): uint =
  result = vbo.id.uint

func target* [B: static bool, I: static int, T] (vbo: VBOObj[B, I, T]): VBOTarget =
  result = vbo.target

func data* [B: static bool, I: static int, T] (vbo: VBOObj[B, I, T]): array[I, T] =
  result = vbo.data

func usage* [B: static bool, I: static int, T] (vbo: VBOObj[B, I, T]): VBOUsage =
  result = vbo.usage

proc `bind`* [I: static int, T] (vbo: var VBO[I, T]): BindedVBO[I, T] =
  when defined(debuggingOpenGL):
    echo &"glBindBuffer({vbo.target}, {vbo.id})"
  opengl.glBindBuffer(opengl.GLenum(vbo.target), vbo.id)
  result = BindedVBO[I, T](
    id: vbo.id,
    target: vbo.target,
    data: vbo.data,
    usage: vbo.usage
  )

proc unbind* [I: static int, T] (vbo: var BindedVBO[I, T]): VBO[I, T] =
  when defined(debuggingOpenGL):
    echo &"glBindBuffer({vbo.target}, 0)"
  opengl.glBindBuffer(opengl.GLenum(vbo.target), 0)
  result = VBO[I, T](
    id: vbo.id,
    target: vbo.target,
    data: vbo.data,
    usage: vbo.usage
  )

proc use* [I: static int, T] (vbo: var VBO[I, T], procedure: proc (vbo: var BindedVBO[I, T])) =
  var bindedVBO = vbo.bind()
  bindedVBO.procedure()
  vbo = bindedVBO.unbind()

proc correspond* (vbo: BindedVBO, program: ProgramObject, name: string, size: int, stride: uint, offset = 0) =
  let index = opengl.GLuint(program[name])
  when defined(debuggingOpenGL):
    echo &"glEnableVertexAttribArray({index})"
    echo &"glVertexAttribPointer({index}, {size}, EGL_FLOAT, false, {stride}, {offset})"
  opengl.glEnableVertexAttribArray(index)
  opengl.glVertexAttribPointer(index, opengl.GLint(size), opengl.EGL_FLOAT, false, opengl.GLsizei(stride), cast[pointer](offset))
