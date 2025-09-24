//! This exposes all of the files within the library to be accessible within the
//! library itself. This file should *not* be exposed publicly.

pub const batch = @import("batch.zig");
pub const errors = @import("errors.zig");
pub const data = @import("data.zig");
pub const database = @import("database.zig");
pub const iterator = @import("iterator.zig");
pub const transaction = @import("transaction.zig");

/// The public facing API of the library.
pub const root = @import("root.zig");

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
