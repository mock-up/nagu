from nimgl/opengl import nil
import vao, vbo, program, shader
import strformat

type
  TextureObj [binded: static bool] = object
    id: opengl.GLuint
    vao: VAO
    quad*: VBO[20, float32]
    elem*: VBO[6, uint8]
    wrapS, wrapT: TextureWrapParameter
    magFilter: TextureMagFilterParameter
    minFilter: TextureMinFilterParameter
    pixels: pointer
    program: ProgramObject
  
  Texture* = ref TextureObj[false]
  BindedTexture* = ref TextureObj[true]

  TextureWrapParameter* {.pure.} = enum
    tInitialValue = 0
    tRepeat = opengl.GL_REPEAT
    tClampToEdge = opengl.GL_CLAMP_TO_EDGE
    tMirroredRepeat = opengl.GL_MIRRORED_REPEAT
  
  TextureMagFilterParameter {.pure.} = enum
    tInitialValue = 0
    tNearest = opengl.GL_NEAREST
    tLinear = opengl.GL_LINEAR
  
  TextureMinFilterParameter {.pure.} = enum
    tInitialValue = 0
    tNearest = opengl.GL_NEAREST
    tLinear = opengl.GL_LINEAR
    tNearestMipmapNearest = opengl.GL_NEAREST_MIPMAP_NEAREST
    tLinearMipmapNearest = opengl.GL_LINEAR_MIPMAP_NEAREST
    tNearestMipmapLinear = opengl.GL_NEAREST_MIPMAP_LINEAR
    tLinearMipmapLinear = opengl.GL_LINEAR_MIPMAP_LINEAR

proc `bind` (texture: var Texture): BindedTexture =
  when defined(debuggingOpenGL):
    echo &"glBindTexture(opengl.GL_TEXTURE_2D, {texture.id})"
  
  opengl.glBindTexture(
    opengl.GL_TEXTURE_2D,
    texture.id
  )
  result = BindedTexture(
    id: texture.id,
    vao: texture.vao,
    quad: texture.quad,
    elem: texture.elem,
    wrapS: texture.wrapS, wrapT: texture.wrapT,
    magFilter: texture.magFilter,
    minFilter: texture.minFilter,
    pixels: texture.pixels,
    program: texture.program
  )

proc unbind (bindedTexture: var BindedTexture): Texture =
  when defined(debuggingOpenGL):
    echo &"glBindTexture(opengl.GL_TEXTURE_2D, 0)"
  opengl.glBindTexture(opengl.GL_TEXTURE_2D, 0)
  result = Texture(
    id: bindedTexture.id,
    vao: bindedTexture.vao,
    quad: bindedTexture.quad,
    elem: bindedTexture.elem,
    wrapS: bindedTexture.wrapS,
    wrapT: bindedTexture.wrapT,
    magFilter: bindedTexture.magFilter,
    minFilter: bindedTexture.minFilter,
    pixels: bindedTexture.pixels,
    program: bindedTexture.program
  )

proc use* (texture: var Texture, procedure: proc (texture: var BindedTexture)) =
  var bindedTexture = texture.bind()
  bindedTexture.procedure()
  texture = bindedTexture.unbind()

proc useVAO* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vao: var BindedVAO)) =
  var bindedVAO = bindedTexture.vao.bind()
  procedure(bindedTexture, bindedVAO)
  vao.unbind()

proc useElem* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vbo: var BindedVBO[6, uint8])) =
  var bindedVBO = bindedTexture.elem.bind()
  procedure(bindedTexture, bindedVBO)
  bindedTexture.elem = bindedVBO.unbind()

proc useQuad* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vbo: var BindedVBO[20, float32])) =
  var bindedVBO = bindedTexture.quad.bind()
  procedure(bindedTexture, bindedVBO)
  bindedTexture.quad = bindedVBO.unbind()

proc assignParameterBoiler (texture: var BindedTexture, name: opengl.GLenum, param: opengl.GLint) =
  when defined(debuggingOpenGL):
    echo &"glTexParameteri(opengl.GL_TEXTURE_2D, {name.repr}, {param.repr})"
  opengl.glTexParameteri(opengl.GL_TEXTURE_2D, name, param)

proc `wrapS=`* (texture: var BindedTexture, wrap_param: TextureWrapParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_WRAP_S, opengl.GLint(wrap_param))

proc `wrapT=`* (texture: var BindedTexture, wrap_param: TextureWrapParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_WRAP_T, opengl.GLint(wrap_param))

proc `magFilter=`* (texture: var BindedTexture, mag_filter_param: TextureMagFilterParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_MAG_FILTER, opengl.GLint(mag_filter_param))

proc `minFilter=`* (texture: var BindedTexture, min_filter_param: TextureMinFilterParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_MIN_FILTER, opengl.GLint(min_filter_param))

proc initPixels (texture: var BindedTexture) =
  opengl.glTexImage2D(
    opengl.GL_TEXTURE_2D, 0, opengl.GLint(opengl.GL_RGB),
    opengl.GLsizei(0), opengl.GLsizei(0),
    0, opengl.GL_RGB, opengl.GL_UNSIGNED_BYTE, nil
  )

proc `pixels=`* (texture: var BindedTexture, width, height: uint, data: pointer) =
  opengl.glTexSubImage2D(
    opengl.GL_TEXTURE_2D, 0, 0, 0,
    opengl.GLsizei(width), opengl.GLsizei(height),
    opengl.GL_RGB, opengl.GL_UNSIGNED_BYTE, data
  )

proc `pixels=`* (
  texture: var BindedTexture,
  img: tuple[
    data: seq[uint8],
    width: int,
    height: int
  ]
) =
  var data = img.data
  when defined(debuggingOpenGL):
    echo &"""glTexImage2D(
  opengl.GL_TEXTURE_2D, 0, GL_RGB,
  {img.width}, {img.height}, 0,
  GL_RGB, GL_UNSIGNED_BYTE, data[0].addr
)"""

  opengl.glTexImage2D(
    opengl.GL_TEXTURE_2D, 0, opengl.GLint(opengl.GL_RGB),
    opengl.GLsizei(img.width), opengl.GLsizei(img.height), 0,
    opengl.GL_RGB, opengl.GL_UNSIGNED_BYTE, data[0].addr
  )

proc `pixels=`* [W, H: static[int], T] (texture: var BindedTexture, data: array[H, array[W, array[4, T]]]) =
  var data = data
  opengl.glTexImage2D(
    opengl.GL_TEXTURE_2D, 0, opengl.GLint(opengl.GL_RGBA),
    opengl.GLsizei(W), opengl.GLsizei(H), 0,
    opengl.GL_RGBA, opengl.GL_UNSIGNED_BYTE, data[0].addr
  )

proc draw* (texture: var BindedTexture) =
  texture.useVAO do (texture: var BindedTexture, vao: var BindedVAO):
    texture.useElem do (texture: var BindedTexture, vbo: var BindedVBO[6, uint8]):
      when defined(debuggingOpenGL):
        echo &"glDrawElements(opengl.GL_TRIANGLES, 6, opengl.GL_UNSIGNED_BYTE, nil)"
      # opengl.glDrawElements(opengl.GL_TRIANGLES, 6, opengl.GL_UNSIGNED_BYTE, nil)
      opengl.glDrawArrays(opengl.GLenum(vdmTriangleFan), 0, 4)

proc pixelStore (texture: var BindedTexture, pname: opengl.GLenum, param: opengl.GLint) =
  opengl.glPixelStorei(pname, param)

func quad: array[20, float32] = [
   0.5'f32, 0.5, 0.0, 1.0, 0.0,
  -0.5,     0.5, 0.0, 0.0, 0.0,
  -0.5,    -0.5, 0.0, 0.0, 1.0,
   0.5,    -0.5, 0.0, 1.0, 1.0,
] # xyz座標 + uv座標

func elem: array[6, uint8] = [
  0'u8, 1, 2, 0, 2, 3
]

proc init* (_: typedesc[Texture],
            vertex_shader_path, fragment_shader_path: string,
           ): Texture =
  result = Texture(
    id: 0, pixels: nil, vao: VAO.init(),
    quad: VBO[20, float32].init(),
    elem: VBO[6, uint8].init(),
    program: nil
  )

  let
    vertex_shader = ShaderObject.make(soVertex, vertex_shader_path)
    fragment_shader = ShaderObject.make(soFragment, fragment_shader_path)

  result.program = ProgramObject.make(vertex_shader, fragment_shader, @["vertex", "texCoord0"], @["mvpMatrix", "frameTex"])
  
  opengl.glGenTextures(1, result.id.addr)
  opengl.glActiveTexture(opengl.GL_TEXTURE0)
  result.use do (texture: var BindedTexture):
    texture.useVAO do (texture: var BindedTexture, vao: var BindedVAO):
      texture.pixelStore(opengl.GL_UNPACK_ALIGNMENT, 1)

      texture.useQuad do (texture: var BindedTexture, vbo: var BindedVBO[20, float32]):
        var quad = quad()
        vbo.target = vtArrayBuffer
        vbo.usage = vuStaticDraw
        vbo.data = quad
        vbo.correspond(texture.program, "vertex", 3, 20, 0)
        vbo.correspond(texture.program, "texCoord0", 2, 20, 12)
      
      texture.useElem do (texture: var BindedTexture, vbo: var BindedVBO[6, uint8]):
        var elem = elem()
        vbo.target = vtArrayBuffer #vtElementArrayBuffer
        vbo.usage = vuStaticDraw
        vbo.data = elem

      texture.program["frameTex"] = 0
      texture.program.applyMatrix("mvpMatrix")
      `wrapS=`(texture, tRepeat)
      `wrapT=`(texture, tRepeat)
      `magFilter=`(texture, TextureMagFilterParameter.tLinear)
      `minFilter=`(texture, TextureMinFilterParameter.tLinear)
