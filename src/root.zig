// Copyright 2026-2026 Rekka contributors
// Licensed under Apache License 2.0 or any later version
// Refer to the LICENSE file included.

pub const analysis = @cImport({
    @cInclude("llvm-c/Analysis.h");
});

pub const bit_reader = @cImport({
    @cInclude("llvm-c/BitReader.h");
});

pub const bit_writer = @cImport({
    @cInclude("llvm-c/BitWriter.h");
});

pub const comdat = @cImport({
    @cInclude("llvm-c/Comdat.h");
});

pub const core = @cImport({
    @cInclude("llvm-c/Core.h");
});

pub const debug_info = @cImport({
    @cInclude("llvm-c/DebugInfo.h");
});

pub const disassembler = @cImport({
    @cInclude("llvm-c/Disassembler.h");
});

pub const err = @cImport({
    @cInclude("llvm-c/Error.h");
});

pub const error_handling = @cImport({
    @cInclude("llvm-c/ErrorHandling.h");
});

pub const execution_engine = @cImport({
    @cInclude("llvm-c/ExecutionEngine.h");
});

pub const ir_reader = @cImport({
    @cInclude("llvm-c/IRReader.h");
});

pub const linker = @cImport({
    @cInclude("llvm-c/Linker.h");
});

pub const ll_jit = @cImport({
    @cInclude("llvm-c/LLJIT.h");
});

pub const ll_jit_utils = @cImport({
    @cInclude("llvm-c/LLJITUtils.h");
});

pub const lto = @cImport({
    @cInclude("llvm-c/lto.h");
});

pub const object = @cImport({
    @cInclude("llvm-c/Object.h");
});

pub const orc_ee = @cImport({
    @cInclude("llvm-c/OrcEE.h");
});

pub const orc = @cImport({
    @cInclude("llvm-c/Orc.h");
});

pub const remarks = @cImport({
    @cInclude("llvm-c/Remarks.h");
});

pub const support = @cImport({
    @cInclude("llvm-c/Support.h");
});

pub const target = @cImport({
    @cInclude("llvm-c/Target.h");
});

pub const target_machine = @cImport({
    @cInclude("llvm-c/TargetMachine.h");
});

pub const pass_builder = @cImport({
    @cInclude("llvm-c/Transforms/PassBuilder.h");
});
