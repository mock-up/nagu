import vao, vbo, mvp_matrix
import glm

type
  ThreeTimeFloat32VBO [V: static int] = VBO[V*3, float32]
    ## コンパイラを騙すために定義している。
    ## そもそも経緯として`ShapeObj.positions`、`ShapeObj.colors`が直接`VBO[V*3, float32]`を持つと、`V*3`がコンパイル時に計算されず`V=5`における`VBO[15,float32]`が落ちてしまう。
    ## ところが構造体のメンバでない場合、つまり`ThreeTimeFloat32VBO`のように直接型変数を受け取って計算する場合はコンパイル時にうまく解釈できる。
    ## 従って定義したわけだが、利用時には`ThreeTimeFloat32VBO[I] is VBO[I*3,float32] == true`と解釈されないことに留意する必要がある。
    ## これに関してはコンパイラが悪く、いかなる場合でも`ThreeTimeFloat32VBO[I]`型は`VBO[I*3,float32]`型であることが保証できるため強制キャストで型を合わせて実行する。
  
  BindedThreeTimeFloat32VBO [V: static int] = BindedVBO[V*3, float32]

  ShapeObj [
    binded: static bool,
    V: static int
  ] = object
    vao: VAO
    positions: ThreeTimeFloat32VBO[V]
    colors: ThreeTimeFloat32VBO[V]
    model_matrix: array[4, VBO[16, float32]]
  
  Shape* [V: static int] = ref ShapeObj[false, V]
  BindedShape* [V: static int] = ref ShapeObj[true, V]

func toTTF [V: static int] (vbo: VBO[V, float32]): ThreeTimeFloat32VBO[V div 3] =
  result = cast[ThreeTimeFloat32VBO[V div 3]](vbo)

func toBindedTTF [V: static int] (vbo: BindedVBO[V, float32]): BindedThreeTimeFloat32VBO[V div 3] =
  result = cast[BindedThreeTimeFloat32VBO[V div 3]](vbo)

func toVBO [V: static int] (ttf: ThreeTimeFloat32VBO[V]): VBO[V*3, float32] =
  result = cast[VBO[V*3, float32]](ttf)

func toBindedVBO [V: static int] (ttf: BindedThreeTimeFloat32VBO[V]): BindedVBO[V*3, float32] =
  result = cast[BindedVBO[V*3, float32]](ttf)

func toBindedShape [V: static int] (shape: Shape[V]): BindedShape[V] =
  result = BindedShape[V](
    vao: shape.vao,
    positions: shape.positions,
    colors: shape.colors,
    model_matrix: shape.model_matrix
  )

proc use* [V: static int] (shape: var Shape[V], procedure: proc (shape: var BindedShape[V])) =
  var
    bindedVAO = shape.vao.bind()
    bindedShape = shape.toBindedShape
  procedure(bindedShape)
  unbind()

proc usePositions* [V: static int] (bindedShape: var BindedShape[V], procedure: proc (shape: var BindedShape[V], positions: var BindedThreeTimeFloat32VBO[V])) =
  var bindedVBO = bindedShape.positions.toVBO.bind().toBindedTTF
  procedure(bindedShape, bindedVBO)
  bindedVBO.unbind()

func toArray [V: static int] (vectors: array[V, Vec3[float32]]): array[V*3, float32] =
  for vec_index, vec in vectors:
    for elem_index, elem in vec.arr:
      result[vec_index*3 + elem_index] = elem

proc make* [V: static int] (
  _: typedesc[Shape],
  positions: array[V, Vec3[float32]],
  colors: array[V, Vec3[float32]]
): Shape[V] =
  let
    positions = toTTF(VBO[V*3, float32].init())
    colors = toTTF(VBO[V*3, float32].init())
  result = Shape[V](
    vao: VAO.init(),
    positions: positions,
    colors: colors,
    model_matrix: ModelMatrix.init()
  )
  result.use do (shape: var BindedShape[V]):
    shape.usePositions do (shape: var BindedShape[V], vbo: var BindedThreeTimeFloat32VBO[V]):
      vbo.data = [vec3(0f, 0, 0), vec3(0f, 0, 0), vec3(0f, 0, 0), vec3(0f, 0, 0)].toArray
