import shape

type
  TriangleObj [binded: static bool] = ShapeObj[binded, 3, 9, 12]
  Triangle* = ref TriangleObj[false]
  BindedTriangle* = ref TriangleObj[true]
