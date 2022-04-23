# Snow

![flakes](flakes.gif)

## Building
If you already have the zig dependencies, you can avoid downloading them as submodules by changing `ziglibs` to their directory in build.zig.

Otherwise, install them with:

```bash
  git clone --recurse-submodules https://github.com/Rekihyt/snow
  cd snow
  zig build run -Drelease-fast
```

Requires epoxy (for Debian based: `apt install libepoxy-dev`).


## Customizing
If you want to personalize it a bit, try changing the number of flakes, the view matrix z value, the wind/gravity in sprite.zig and/or the size of flakes in the geom shader.

