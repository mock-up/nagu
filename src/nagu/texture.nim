from nimgl/opengl import nil
import glm
import vao, vbo, program, shader, utils, position
import types/texture
import strformat

import tables

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

proc useUV* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vbo: var BindedTextureUV)) =
  var bindedVBO = bindedTexture.uv.bind()
  procedure(bindedTexture, bindedVBO)
  bindedTexture.uv = bindedVBO.unbind()

proc useModelMatrix* (bindedTexture: var BindedTexture, procedure: proc (texture: var BindedTexture, vbo: var array[4, BindedTextureModelMatrixVector])) =
  discard
  # var
  #   bindedVec1VBO = bindedTexture.model_matrix[0].bind()
  # procedure(bindedTexture, bindedVBO)
  # bindedTexture.model_matrix[index] = bindedVBO.unbind()
  # めっちゃ難しい。行列に対する操作をしつつbind管理もしなければいけない
  # 仮想的な行列を持って置いて、代入するタイミングで順番にuseModelMatrixVectorを回すのが良いのかも。

proc useModelMatrixVector* (bindedTexture: var BindedTexture, index: range[0..3], procedure: proc (texture: var BindedTexture, vbo: var BindedTextureModelMatrixVector)) =
  var bindedVBO = bindedTexture.model_matrix[index].bind()
  procedure(bindedTexture, bindedVBO)
  bindedTexture.model_matrix[index] = bindedVBO.unbind()

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

func quad (base_pos: Position): array[12, float32] =
  let (x, y, z) = base_pos.coord
  result = [
     0.1'f32 + x,  0.1 + y, 0.0 + z,
    -0.1 + x,      0.1 + y, 0.0 + z,
    -0.1 + x,     -0.1 + y, 0.0 + z,
     0.1 + x,     -0.1 + y, 0.0 + z,
  ]

func uv: array[8, float32] = [
  1.0'f32, 0.0,
  0.0,     0.0,
  0.0,     1.0,
  1.0,     1.0
]

func elem: array[6, uint8] = [
  0'u8, 1, 2, 0, 2, 3
]

# proc `[]=`* (texture: var BindedTexture, name: string, matrix4v: array[16, float32]) =
# そのうち一般化する、VBO名に依存したuse関数を作るのをやめる、customなvertex attrib変数に対して
# 適用できるUse関数を定義する
# VBOを専用のフィールドで持つのではなくテーブルに持っておくと良いと思う
proc setModelMatrix* (texture: var BindedTexture, matrix4v: array[16, float32]) =
  for index in 0 ..< 4:
    let matrix = [
      matrix4v[index*4], matrix4v[index*4+1], matrix4v[index*4+2], matrix4v[index*4+3],
      matrix4v[index*4], matrix4v[index*4+1], matrix4v[index*4+2], matrix4v[index*4+3],
      matrix4v[index*4], matrix4v[index*4+1], matrix4v[index*4+2], matrix4v[index*4+3],
      matrix4v[index*4], matrix4v[index*4+1], matrix4v[index*4+2], matrix4v[index*4+3],
    ]
    texture.useModelMatrixVector(index) do (texture: var BindedTexture, vbo: var BindedTextureModelMatrixVector):
      vbo.data = matrix
      texture.program[&"modelMatrixVec{index+1}"] = (vbo, 4)

proc toArray[T] (matrix4v: Mat4[T]): array[16, T] =
  for vec_index, vec in matrix4v.arr:
    for elem_index, elem in vec.arr:
      result[vec_index * 4 + elem_index] = elem

proc setModelMatrix* (texture: var BindedTexture, matrix4v: Mat4[float32]) =
  setModelMatrix(texture, matrix4v.toArray)

proc make* (_: typedesc[Texture],
            position: Position = Position.init(0, 0, 0),
            vertex_shader_path: string,
            fragment_shader_path: string,
           ): Texture =

  result = Texture.init(
    vao = VAO.init(),
    quad = TextureQuad.init(),
    uv = TextureUV.init(),
    elem = TextureElem.init(),
    model_matrix = [
                      TextureModelMatrixVector.init(),
                      TextureModelMatrixVector.init(),
                      TextureModelMatrixVector.init(),
                      TextureModelMatrixVector.init()
                    ]
  )

  let
    vertex_shader = ShaderObject.make(soVertex, vertex_shader_path)
    fragment_shader = ShaderObject.make(soFragment, fragment_shader_path)

  result.program = ProgramObject.make(
    vertex_shader,
    fragment_shader,
    @["vertex", "texCoord0", "modelMatrixVec1", "modelMatrixVec2", "modelMatrixVec3", "modelMatrixVec4"],
    @["frameTex", "mvpMatrix"],
    # @[(soVertex, "mvpMatrix")]
  )
  result.use do (texture: var BindedTexture):
    texture.useVAO do (texture: var BindedTexture, vao: var BindedVAO):
      texture.pixelStore(opengl.GL_UNPACK_ALIGNMENT, 1)

      texture.useQuad do (texture: var BindedTexture, vbo: var BindedTextureQuad):
        vbo.data = quad(position)
        texture.program["vertex"] = (vbo, 3)

      texture.useUV do (texture: var BindedTexture, vbo: var BindedTextureUV):
        vbo.data = uv()
        texture.program["texCoord0"] = (vbo, 2)
      
      texture.setModelMatrix(identityMatrix())
      
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
