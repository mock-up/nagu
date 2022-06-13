when isMainModule:
  import nagu
  import pnm

  var
    naguContext = setup(1000, 1000, "default")

    sea_tex = Texture.make(
      Position.init(0.1, -0.1, 0),
      "assets/vertex/id.glsl",
      "assets/fragment/id.glsl"
    )
    sea = pnm.readPPMFile("assets/sea.ppm")

    cat_tex = Texture.make(
      Position.init(-0.4, 0.4, 0),
      "assets/vertex/id.glsl",
      "assets/fragment/id.glsl"
    )
    cat = pnm.readPPMFile("assets/cat.ppm")

  sea_tex.use do (texture: var BindedTexture):
    texture.pixels = (data: sea.data, width: sea.col, height: sea.row)

  cat_tex.use do (texture: var BindedTexture):
    texture.pixels = (data: cat.data, width: cat.col, height: cat.row)

  var v: float32 = 1.0
  naguContext.update:
    naguContext.clear(toColor("#ffffff"))
    sea_tex.use do (texture: var BindedTexture):
      texture.draw()
      texture.useModelMatrixVector(0) do (texture: var BindedTexture, vbo: var BindedTextureModelMatrixVector):
        vbo.data = [
          v, 0.0, 0.0, 0.0,
          v, 0.0, 0.0, 0.0,
          v, 0.0, 0.0, 0.0,
          v, 0.0, 0.0, 0.0,
        ]
        texture.program["modelMatrixVec1"] = (vbo, 4)
      v += 0.01
    cat_tex.use do (texture: var BindedTexture):
      texture.draw()