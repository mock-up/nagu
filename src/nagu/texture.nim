from nimgl/opengl import nil
import vao, vbo, program, shader, utils, position
import types/[texture]
import strformat

proc `bind` (texture: var Texture): BindedTexture =  
  opengl.glBindTexture(opengl.GL_TEXTURE_2D, texture.id)
  result = texture.toBindedTexture

  debugOpenGLStatement:
    echo &"glBindTexture(GL_TEXTURE_2D, {texture.id})"

proc unbind (bindedTexture: var BindedTexture): Texture =
  opengl.glBindTexture(opengl.GL_TEXTURE_2D, 0)
  result = bindedTexture.toTexture

  debugOpenGLStatement:
    echo &"glBindTexture(GL_TEXTURE_2D, 0)"

proc use* (texture: var Texture, procedure: proc (texture: var BindedTexture)) =
  var bindedTexture = texture.bind()
  bindedTexture.procedure()
  texture = bindedTexture.unbind()

proc useVAO* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vao: var BindedVAO)) =
  var bindedVAO = bindedTexture.vao.bind()
  procedure(bindedTexture, bindedVAO)
  vao.unbind()

proc useElem* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vbo: var BindedTextureElem)) =
  var bindedVBO = bindedTexture.elem.bind()
  procedure(bindedTexture, bindedVBO)
  bindedTexture.elem = bindedVBO.unbind()

proc useQuad* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vbo: var BindedTextureQuad)) =
  var bindedVBO = bindedTexture.quad.bind()
  procedure(bindedTexture, bindedVBO)
  bindedTexture.quad = bindedVBO.unbind()

proc `pixels=`* (texture: var BindedTexture, width, height: uint, data: pointer) =
  opengl.glTexSubImage2D(
    opengl.GL_TEXTURE_2D, 0, 0, 0,
    opengl.GLsizei(width), opengl.GLsizei(height),
    opengl.GL_RGB, opengl.GL_UNSIGNED_BYTE, data
  )

proc `pixels=`* (
  texture: var BindedTexture,
  img: tuple[data: seq[uint8], width: int, height: int]
) =
  var data = img.data
  if texture.initializedPixels:
    opengl.glTexSubImage2D(
      opengl.GL_TEXTURE_2D, 0, 0, 0,
      opengl.GLsizei(img.width), opengl.GLsizei(img.height),
      opengl.GL_RGB, opengl.GL_UNSIGNED_BYTE, data[0].addr
    )
  else:
    opengl.glTexImage2D(
      opengl.GL_TEXTURE_2D, 0, opengl.GLint(opengl.GL_RGB),
      opengl.GLsizei(img.width), opengl.GLsizei(img.height), 0,
      opengl.GL_RGB, opengl.GL_UNSIGNED_BYTE, data[0].addr
    )
    texture.initializedPixels = true
  echo "update"
  
  debugOpenGLStatement:
    echo &"glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, {img.width}, {img.height}, 0, GL_RGB, GL_UNSIGNED_BYTE, data[0].addr)"

proc `pixels=`* [W, H: static[int], T] (texture: var BindedTexture, data: array[H, array[W, array[4, T]]]) =
  var data = data
  opengl.glTexImage2D(
    opengl.GL_TEXTURE_2D, 0, opengl.GLint(opengl.GL_RGBA),
    opengl.GLsizei(W), opengl.GLsizei(H), 0,
    opengl.GL_RGBA, opengl.GL_UNSIGNED_BYTE, data[0].addr
  )

proc draw* (texture: var BindedTexture) =
  texture.useVAO do (texture: var BindedTexture, vao: var BindedVAO):
    texture.useElem do (texture: var BindedTexture, vbo: var BindedTextureElem):
      opengl.glDrawArrays(opengl.GLenum(vdmTriangleFan), 0, 4)

      debugOpenGLStatement:
        echo &"glDrawArrays(vdmTriangleFan, 0, 4)"

proc pixelStore (texture: var BindedTexture, pname: opengl.GLenum, param: opengl.GLint) =
  opengl.glPixelStorei(pname, param)

  debugOpenGLStatement:
    echo &"glPixelStorei({pname.repr}, {param.repr})"

func quad (base_pos: Position): array[20, float32] =
  let (x, y, z) = base_pos.coord
  result = [
     0.1'f32 + x,  0.1 + y, 0.0 + z, 1.0, 0.0,
    -0.1 + x,      0.1 + y, 0.0 + z, 0.0, 0.0,
    -0.1 + x,     -0.1 + y, 0.0 + z, 0.0, 1.0,
     0.1 + x,     -0.1 + y, 0.0 + z, 1.0, 1.0,
  ] # xyz座標 + uv座標

func elem: array[6, uint8] = [
  0'u8, 1, 2, 0, 2, 3
]

proc make* (_: typedesc[Texture],
            position: Position = Position.init(0, 0, 0),
            vertex_shader_path: string,
            fragment_shader_path: string,
           ): Texture =
  result = Texture.init(vao=VAO.init(), quad=TextureQuad.init(), elem=TextureElem.init())

  let
    vertex_shader = ShaderObject.make(soVertex, vertex_shader_path)
    fragment_shader = ShaderObject.make(soFragment, fragment_shader_path)

  result.program = ProgramObject.make(
    vertex_shader,
    fragment_shader,
    @["vertex", "texCoord0"],
    @["frameTex"],
    @[(soVertex, "mvpMatrix")]
  )
  result.use do (texture: var BindedTexture):
    texture.useVAO do (texture: var BindedTexture, vao: var BindedVAO):
      texture.pixelStore(opengl.GL_UNPACK_ALIGNMENT, 1)

      texture.useQuad do (texture: var BindedTexture, vbo: var BindedTextureQuad):
        var quad = quad(position)
        vbo.target = vtArrayBuffer
        vbo.usage = vuStaticDraw
        vbo.data = quad
        vbo.correspond(texture.program, "vertex", 3, 20, 0)
        vbo.correspond(texture.program, "texCoord0", 2, 20, 12)
      
      texture.useElem do (texture: var BindedTexture, vbo: var BindedTextureElem):
        var elem = elem()
        vbo.target = vtArrayBuffer
        vbo.usage = vuStaticDraw
        vbo.data = elem

      texture.program["frameTex"] = 0
      texture.program["mvpMatrix"] = identityMatrix()
      texture.wrapS = tRepeat
      texture.wrapT = tRepeat
      texture.magFilter = TextureMagFilterParameter.tLinear
      texture.minFilter = TextureMinFilterParameter.tLinear
