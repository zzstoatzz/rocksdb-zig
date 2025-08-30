const std = @import("std");
const rdb = @import("rocksdb");
const lib = @import("lib.zig");

const Data = lib.Data;

/// Use this to tell rocksdb what you'd like to do with the error message string
/// when there is an error.
///
/// If you don't use this, a zig error will still be returned when there is an
/// error. But this can help you get more context with an error message that
/// comes from rocksdb.
pub const ErrorHandler = union(enum) {
    /// Do nothing. Simply discard the error message.
    noop,
    /// Print the error to stderr.
    print,
    /// Return the string through this pointer.
    write: *?Data,
    /// Perform an arbitrary user-defined action with the string.
    call_borrowed: struct {
        ctx: *anyopaque,
        /// the string is borrowed here and does not exceed the lifetime of this call
        impl: *const fn (ctx: *anyopaque, anyerror, string: []const u8) void,
    },

    pub fn handle(self: ErrorHandler, err: anyerror, err_str: [*:0]u8) void {
        const data = Data{
            .data = std.mem.span(err_str),
            .free = rdb.rocksdb_free,
        };
        switch (self) {
            .noop => data.deinit(),
            .print => {
                std.debug.print("rocksdb {} - {s}", .{ err, data.data });
                data.deinit();
            },
            .write => |ptr| ptr.* = data,
            .call_borrowed => |item| {
                item.impl(item.ctx, err, data.data);
                data.deinit();
            },
        }
    }
};
