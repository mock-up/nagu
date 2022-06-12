from nimgl/opengl import nil
import ../vao, ../vbo, ../program
import strformat

type
  TextureQuad* = VBO[20, float32]
  BindedTextureQuad* = BindedVBO[20, float32]
  TextureElem* = VBO[6, uint8]
  BindedTextureElem* = BindedVBO[6, uint8]

  TextureObj [binded: static bool] = object
    id: opengl.GLuint
    vao*: VAO
    quad*: TextureQuad
    elem*: TextureElem
    wrapS, wrapT: TextureWrapParameter
    magFilter: TextureMagFilterParameter
    minFilter: TextureMinFilterParameter
    pixels: pointer
    program*: ProgramObject
    initializedPixels*: bool
  
  Texture* = ref TextureObj[false]
  BindedTexture* = ref TextureObj[true]
  AllTextures = Texture | BindedTexture

  TextureWrapParameter* {.pure.} = enum
    tInitialValue = 0
    tRepeat = opengl.GL_REPEAT
    tClampToEdge = opengl.GL_CLAMP_TO_EDGE
    tMirroredRepeat = opengl.GL_MIRRORED_REPEAT
  
  TextureMagFilterParameter* {.pure.} = enum
    tInitialValue = 0
    tNearest = opengl.GL_NEAREST
    tLinear = opengl.GL_LINEAR
  
  TextureMinFilterParameter* {.pure.} = enum
    tInitialValue = 0
    tNearest = opengl.GL_NEAREST
    tLinear = opengl.GL_LINEAR
    tNearestMipmapNearest = opengl.GL_NEAREST_MIPMAP_NEAREST
    tLinearMipmapNearest = opengl.GL_LINEAR_MIPMAP_NEAREST
    tNearestMipmapLinear = opengl.GL_NEAREST_MIPMAP_LINEAR
    tLinearMipmapLinear = opengl.GL_LINEAR_MIPMAP_LINEAR

func toBindedTexture* (texture: Texture): BindedTexture =
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

func toTexture* (texture: BindedTexture): Texture =
  result = Texture(
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

func id* (texture: AllTextures): opengl.GLuint = texture.id

func wrapS* (texture: AllTextures): TextureWrapParameter = texture.wrapS

func wrapT* (texture: AllTextures): TextureWrapParameter = texture.wrapT

func magFilter* (texture: AllTextures): TextureMagFilterParameter = texture.magFilter

func minFilter* (texture: AllTextures): TextureMinFilterParameter = texture.minFilter

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

proc init* (_: typedesc[Texture],
            id: opengl.GLuint = 0,
            vao: VAO = nil,
            quad: TextureQuad = nil,
            elem: TextureElem = nil,
            wrapS: TextureWrapParameter = TextureWrapParameter.tInitialValue,
            wrapT: TextureWrapParameter = TextureWrapParameter.tInitialValue,
            magFilter: TextureMagFilterParameter = TextureMagFilterParameter.tInitialValue,
            minFilter: TextureMinFilterParameter = TextureMinFilterParameter.tInitialValue,
            program: ProgramObject = nil
           ): Texture =
  result = Texture(id: id, vao: vao, quad: quad, elem: elem, wrapS: wrapS, wrapT: wrapT, magFilter: magFilter, minFilter: minFilter, program: program)
  opengl.glGenTextures(1, result.id.addr)
  opengl.glActiveTexture(opengl.GL_TEXTURE0)