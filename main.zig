const std = @import("std");
const Allocator = std.mem.Allocator;

const Options = struct {
    num: ?u32,
    name: ?[]const u8,
    include: bool = false,

    pub fn init() Options {
        return Options{
            .num = null,
            .name = null,
            .include = false,
        };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var opts = Options.init();
    try parse(args, Options, &opts);
    std.debug.print("args={any}\n", .{opts});
}

const ArgIterator = struct {
    args: [][:0]u8,
    index: usize,

    fn init(args: *const [][:0]u8) ArgIterator {
        return ArgIterator{
            .args = args.*,
            .index = 0,
        };
    }

    fn next(self: *ArgIterator) ?[]const u8 {
        if (self.index >= self.args.len) {
            return null;
        }
        const arg = self.args[self.index];
        self.index += 1;
        return arg;
    }
};

pub fn parse(args: [][:0]u8, comptime T: type, obj: *T) !void {
    std.debug.print("typ={any} obj={any}\n", .{ T, obj });

    var it = ArgIterator.init(&args);
    const fields = std.meta.fields(T);
    while (it.next()) |arg| {
        std.debug.print("arg: {s}\n", .{arg});
        inline for (fields) |field| {
            const name = "--" ++ field.name;
            if (std.mem.eql(u8, arg, name)) {
                std.debug.print("field={s} type={any}\n", .{ field.name, field.type });
                switch (field.type) {
                    ?u32 => {
                        const val = it.next();
                        if (val != null) {
                            @field(obj, field.name) = try std.fmt.parseInt(u32, val.?, 10);
                        }
                    },
                    ?[]const u8 => {
                        const val = it.next();
                        if (val != null) {
                            @field(obj, field.name) = val.?;
                        }
                    },
                    []const u8 => {
                        const val = it.next() orelse return std.debug.panic("missing value for {s}\n", .{field.name});
                        std.debug.print("val={s}\n", .{val});
                        @field(obj, field.name) = val;
                    },
                    bool => {
                        @field(obj, field.name) = true;
                    },
                    else => {},
                }
            }
        }
    }
}

// pub fn calcJump(self: *Z80, byte: u8) void {
//     const offset: i8 = @bitCast(byte);
//     std.debug.print("pc={d} offset={d}\n", .{ self.pc, offset });
//     if (offset > 0) {
//         self.pc +%= @as(u8, @intCast(offset));
//     } else {
//         self.pc -%= @as(u8, @intCast(-offset));
//     }
// }
