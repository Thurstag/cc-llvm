# Cross-compiled LLVM

[![Continuous Integration](https://github.com/rekka-lang/cc-llvm/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/rekka-lang/cc-llvm/actions/workflows/ci.yml)

A library exposing the C API of LLVM and offering cross-compilation thanks to [Zig](https://ziglang.org/). It mainly relies on the work done by [Trevor Swan](https://github.com/trevorswan11) for [ghoti](https://github.com/trevorswan11/ghoti).

## Getting started

### Installation

Use `zig fetch`.

[TODO: Switch to a release when it is done]: #
```bash
zig fetch --save git+https://github.com/rekka-lang/cc-llvm.git
```

### Usage

Import the module in your `build.zig`.
```zig
const cc_llvm = b.dependency("cc_llvm", .{ .target = target, .optimize = optimize });

your_module.addImport("llvm", cc_llvm.module("llvm"));
```

There is also a `WriteFiles` containing all the license files that you have to distribute.
```zig
b.installDirectory(.{
    .install_dir = .bin,
    .install_subdir = "third-party",
    .source_dir = cc_llvm.namedWriteFiles("licenses").getDirectory(),
});
```

Here is a little snippet of an API call:
```zig
const std = @import("std");

const llvm = @import("llvm");

pub fn main(_: std.process.Init) !void {
    var major: c_uint = undefined;
    var minor: c_uint = undefined;
    var patch: c_uint = undefined;
    llvm.core.LLVMGetVersion(&major, &minor, &patch);

    std.log.info("The version of LLVM is \"{}.{}.{}\".", .{ major, minor, patch });
}
```

## Contributing

Please see [Contributing](./CONTRIBUTING.md) for more information on how to get involved.
