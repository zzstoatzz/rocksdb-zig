const std = @import("std");
const rdb = @import("rocksdb");
const lib = @import("private.zig");

const Allocator = std.mem.Allocator;

const CallHandler = lib.errors.CallHandler;
const ColumnFamilyHandle = lib.root.ColumnFamilyHandle;
const Data = lib.root.Data;
const ErrorHandler = lib.root.ErrorHandler;

pub const Transaction = struct {
    inner: *rdb.rocksdb_transaction_t,

    const Self = @This();

    pub fn deinit(self: Transaction) void {
        rdb.rocksdb_transaction_destroy(self.inner);
    }

    pub fn commit(
        self: Transaction,
        error_handler: ErrorHandler,
    ) error{RocksDBTransactionCommit}!void {
        var ch = CallHandler.init(error_handler);
        try ch.handle(rdb.rocksdb_transaction_commit(self.inner), error.RocksDBTransactionCommit);
    }

    pub fn put(
        self: *const Self,
        column_family: ColumnFamilyHandle,
        key: []const u8,
        value: []const u8,
        error_handler: ErrorHandler,
    ) error{RocksDBTransactionPut}!void {
        var ch = CallHandler.init(error_handler);
        try ch.handle(rdb.rocksdb_transaction_put_cf(
            self.inner,
            column_family,
            key.ptr,
            key.len,
            value.ptr,
            value.len,
            @ptrCast(&ch.err_str_in),
        ), error.RocksDBTransactionPut);
    }

    pub fn get(
        self: *const Self,
        column_family: ColumnFamilyHandle,
        key: []const u8,
        error_handler: ErrorHandler,
    ) error{RocksDBTransactionGet}!Data {
        var valueLength: usize = 0;
        var ch = CallHandler.init(error_handler);
        const value = try ch.handle(rdb.rocksdb_transaction_get_cf(
            self.inner,
            column_family,
            key.ptr,
            key.len,
            &valueLength,
            @ptrCast(&ch.err_str_in),
        ), error.RocksDBTransactionGet);
        if (value == 0) {
            return null;
        }
        return .{
            .free = rdb.rocksdb_free,
            .data = value[0..valueLength],
        };
    }
};
