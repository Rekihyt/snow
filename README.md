# Snow

![flakes](flakes.gif)

## Building
If you already have the zig dependencies, you can avoid downloading them as submodules by changing their paths in build.zig.

Otherwise, install them with:

```bash
  git clone --recurse-submodules https://github.com/Rekihyt/snow
  cd snow
  zig build run -Doptimize=ReleaseFast
```

## Running
To run the executable directly it must be in a directory with a `sprites` folder, with textures in it.

## Customizing
If you want to personalize it a bit, try changing the number of flakes, the view matrix z value, the wind/gravity in sprite.zig and/or the size of flakes in the geom shader. You can also change the textures used by setting `texture_count` and putting new files in the `sprites` directory.

## Performance
This program uses opengl directly with geometry shaders. My nvidia 1060 can render about 1-2 million flakes before going under 60fps. The default hardcoded settings use <1% CPU and 1-2% of my GPU.