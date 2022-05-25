from nimgl/opengl import nil

type
  TextureObj [binded: static bool] = object
    id: opengl.GLuint
    wrapS, wrapT: TextureWrapParameter
    magFilter: TextureMagFilterParameter
    minFilter: TextureMinFilterParameter
    pixels: pointer
  
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
  opengl.glBindTexture(
    opengl.GL_TEXTURE_2D,
    texture.id
  )
  result = BindedTexture(id: texture.id)

proc unbind =
  opengl.glBindTexture(opengl.GL_TEXTURE_2D, 0)

proc use* (texture: var Texture, procedure: proc (texture: var BindedTexture)) =
  var bindedTexture = texture.bind()
  bindedTexture.procedure()
  unbind()

proc assignParameterBoiler (texture: var BindedTexture, name: opengl.GLenum, param: opengl.GLint) =
  opengl.glTexParameteri(opengl.GL_TEXTURE_2D, name, param)

proc `wrapS=`* (texture: var BindedTexture, wrap_param: TextureWrapParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_WRAP_S, opengl.GLint(wrap_param))

proc `wrapT=`* (texture: var BindedTexture, wrap_param: TextureWrapParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_WRAP_T, opengl.GLint(wrap_param))

proc `magFilter=`* (texture: var BindedTexture, mag_filter_param: TextureMagFilterParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_MAG_FILTER, opengl.GLint(mag_filter_param))

proc `minFilter=`* (texture: var BindedTexture, min_filter_param: TextureMinFilterParameter) =
  texture.assignParameterBoiler(opengl.GL_TEXTURE_MIN_FILTER, opengl.GLint(min_filter_param))

proc initPixels (texture: var BindedTexture, width, height: uint) =
  opengl.glTexImage2D(
    opengl.GL_TEXTURE_2D, 0, opengl.GLint(opengl.GL_RGBA),
    opengl.GLsizei(width), opengl.GLsizei(height),
    0, opengl.GL_RGBA, opengl.GL_UNSIGNED_BYTE, nil
  )

proc `pixels=`* (texture: var BindedTexture, width, height: uint, data: pointer) =
  opengl.glTexSubImage2D(
    opengl.GL_TEXTURE_2D, 0, 0, 0,
    opengl.GLsizei(width), opengl.GLsizei(height),
    opengl.GL_RGBA, opengl.GL_UNSIGNED_BYTE, data
  )

proc init* (_: typedesc[Texture], width, height: uint): Texture =
  result = Texture(id: 0, pixels: nil)
  opengl.glGenTextures(1, result.id.addr)
  result.use do (texture: var BindedTexture):
    texture.initPixels(width, height)
    texture.wrapS = tClampToEdge
    texture.wrapT = tClampToEdge
    texture.magFilter = TextureMagFilterParameter.tLinear
    texture.minFilter = TextureMinFilterParameter.tLinear
