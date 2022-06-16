when isMainModule:
  import nagu
  import pnm
  import glm

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

    shape = Shape[4, 12, 16].make(
      [vec3(0f, 0, 0), vec3(1f, 0, 0), vec3(1f, 1, 0), vec3(0f, 1, 0)],
      [vec4(0f, 0, 0, 1), vec4(0f, 0, 0, 1), vec4(0f, 0, 0, 1), vec4(0f, 0, 0, 1)],
      "assets/shapes/id/id.vert",
      "assets/shapes/id/id.frag"
    )
  
  sea_tex.use do (texture: var BindedTexture):
    texture.pixels = (data: sea.data, width: sea.col, height: sea.row)

  cat_tex.use do (texture: var BindedTexture):
    texture.pixels = (data: cat.data, width: cat.col, height: cat.row)

  var v: float32 = 1.0
  naguContext.update:
    naguContext.clear(toColor("#ffffff"))
    sea_tex.use do (texture: var BindedTexture):
      texture.draw()
      texture.setModelMatrix(mat4(1f).rotate(v, vec3(1f, 1, 1)))
    cat_tex.use do (texture: var BindedTexture):
      texture.draw()
      texture.setModelMatrix(mat4(1f).rotate(2*v, vec3(1f, 0, 1)))
    v += 0.01
