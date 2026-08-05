// Copyright 2026-2026 Rekka contributors
// Licensed under Apache License 2.0 or any later version
// Refer to the LICENSE file included.

const std = @import("std");

const build_info = @import("build.zig.zon");
const LLVMBuilder = @import("submodules/ghoti/third-party/llvm/LLVMBuilder.zig");

fn checkLlvmVersion(b: *std.Build) !void {
    const check_llvm_version = "check_llvm_version";
    const check_llvm_version_step = b.step(check_llvm_version, "Check that the version of this package matches the version of the exposed LLVM.");

    const target = b.graph.host;
    const llvm = try addLlvmModule(b, target, std.builtin.OptimizeMode.Debug);

    var run_check_llvm_version = b.addRunArtifact(b.addExecutable(.{
        .name = check_llvm_version,
        .root_module = b.createModule(.{
            .root_source_file = b.path(std.fmt.comptimePrint("scripts/{s}.zig", .{check_llvm_version})),
            .target = target,
            .imports = &.{
                .{ .name = llvm.name, .module = llvm.module },
            },
        }),
    }));
    run_check_llvm_version.addArg(build_info.version);

    check_llvm_version_step.dependOn(&run_check_llvm_version.step);

    b.getInstallStep().dependOn(check_llvm_version_step);
}

fn addLicenses(b: *std.Build, target: std.Target) !*std.Build.Step.WriteFile {
    const licenses = b.addNamedWriteFiles("licenses");

    const llvm = b.dependency("llvm", .{});
    _ = licenses.addCopyFile(b.path("LICENSE"), "cc-llvm");
    _ = licenses.addCopyFile(llvm.path("LICENSE.TXT"), "LLVM.TXT");
    _ = licenses.addCopyFile(llvm.path("llvm/include/llvm/Support/LICENSE.TXT"), "LLVM System Interface Library.TXT");
    _ = licenses.addCopyFile(llvm.path("llvm/lib/Support/BLAKE3/LICENSE"), "BLAKE3");
    _ = licenses.addCopyFile(b.dependency("zlib", .{}).path("LICENSE"), "zlib");
    _ = licenses.addCopyFile(b.dependency("libxml2", .{}).path("Copyright"), "libxml2");
    _ = licenses.addCopyFile(b.dependency("zstd", .{}).path("LICENSE"), "zstd");

    var run_copy_zig_install_files = b.addRunArtifact(b.addExecutable(.{
        .name = "copy_zig_install_files",
        .root_module = b.createModule(.{
            .root_source_file = b.path("scripts/copy_zig_install_files.zig"),
            .target = b.graph.host,
        }),
    }));
    const zig_with_licenses_only = run_copy_zig_install_files.addOutputDirectoryArg("zig");
    run_copy_zig_install_files.addArg(std.Build.LazyPath.dirname(.{ .cwd_relative = b.graph.zig_lib_directory.path orelse @panic("Unknown zig library directory") }).getDisplayName());

    var zig_licenses: std.ArrayList(struct { path: []const u8, final_name: []const u8 }) = .empty;
    defer zig_licenses.deinit(b.allocator);
    try zig_licenses.appendSlice(b.allocator, &.{
        .{ .path = "LICENSE", .final_name = "zig" },
        .{ .path = "lib/libcxx/LICENSE.TXT", .final_name = "libcxx.TXT" },
        .{ .path = "lib/libcxxabi/LICENSE.TXT", .final_name = "libcxxabi.TXT" },
        .{ .path = "lib/libunwind/LICENSE.TXT", .final_name = "libunwind.TXT" },
    });
    if (target.isMuslLibC()) {
        try zig_licenses.append(b.allocator, .{ .path = "lib/libc/musl/COPYRIGHT", .final_name = "musl" });
    } else if (target.isGnuLibC()) {
        try zig_licenses.append(b.allocator, .{ .path = "lib/libc/glibc/LICENSES", .final_name = "glibc" });
    } else {
        const message = try std.fmt.allocPrint(b.allocator, "The copy of {} libc's license is not implemented", .{target.abi});
        defer b.allocator.free(message);
        @panic(message);
    }

    for (zig_licenses.items) |license| {
        run_copy_zig_install_files.addArg(license.path);

        _ = licenses.addCopyFile(zig_with_licenses_only.path(b, license.path), license.final_name);
    }

    return licenses;
}

fn buildLtoFromTools(builder: *LLVMBuilder) *std.Build.Step.Compile {
    return builder.createLLVMLibrary(.{ .name = "LTO", .cxx_source_files = .{
        .root = builder.metadata.root.path(builder.b, "llvm/tools/lto"),
        .files = &.{
            "LTODisassembler.cpp",
            "lto.cpp",
        },
    }, .additional_include_paths = &.{
        builder.target_artifacts.intrinsics_gen.getDirectory(),
        builder.configure_phase_artifacts.gen_vt.getDirectory(),
        builder.metadata.extension_def.getDirectory(),
    }, .config_headers = &.{
        builder.target_artifacts.config_headers.disassemblers_def,
        builder.target_artifacts.config_headers.asm_printers_def,
        builder.target_artifacts.config_headers.asm_parsers_def,
        builder.target_artifacts.config_headers.target_mcas_def,
        builder.target_artifacts.config_headers.abi_breaking_h,
        builder.target_artifacts.config_headers.llvm_config_h,
        builder.target_artifacts.config_headers.targets_def,
    } });
}

const ModuleWithName = struct {
    name: []const u8,
    module: *std.Build.Module,
};

fn addLlvmModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !ModuleWithName {
    const llvm_builder = LLVMBuilder.init(b);
    llvm_builder.build(.{
        // Do not build kaleidoscope
        .behavior = .package,
        .target = target,
    });

    const name = "llvm";
    const module = b.addModule(name, .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const llvm_include_paths = llvm_builder.allIncludePaths();
    for (llvm_include_paths.includes) |include| {
        module.addIncludePath(include);
    }
    for (llvm_include_paths.config_headers) |config_header| {
        module.addConfigHeader(config_header);
    }
    // TODO: Create a PR to add it to ghoti ?
    module.addConfigHeader(llvm_builder.target_artifacts.config_headers.llvm_config_h);

    for (llvm_builder.allTargetArtifacts()) |artifact| {
        module.linkLibrary(artifact);
    }
    // TODO: Create a PR to add it to ghoti ?
    module.linkLibrary(buildLtoFromTools(llvm_builder));

    return .{
        .name = name,
        .module = module,
    };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = try addLlvmModule(b, target, optimize);

    _ = try checkLlvmVersion(b);

    _ = try addLicenses(b, target.result);
}
