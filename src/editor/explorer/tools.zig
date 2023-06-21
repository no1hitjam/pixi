const std = @import("std");
const zgui = @import("zgui");
const pixi = @import("root");

pub fn draw() void {
    zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.item_spacing, .v = .{ 8.0 * pixi.state.window.scale[0], 8.0 * pixi.state.window.scale[1] } });
    zgui.pushStyleVar2f(.{ .idx = zgui.StyleVar.selectable_text_align, .v = .{ 0.5, 0.8 } });
    defer zgui.popStyleVar(.{ .count = 2 });

    zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.header, .c = pixi.state.style.foreground.toSlice() });
    zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.header_hovered, .c = pixi.state.style.foreground.toSlice() });
    zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.header_active, .c = pixi.state.style.foreground.toSlice() });
    defer zgui.popStyleColor(.{ .count = 3 });
    if (zgui.beginChild("Tools", .{ .h = zgui.getWindowHeight() / 4.0 })) {
        defer zgui.endChild();

        const style = zgui.getStyle();
        const window_size = zgui.getWindowSize();

        const button_width = window_size[0] / 4.0;
        const button_height = button_width / 2.0;

        const color_width = window_size[0] / 2.2;

        // Row 1
        {
            zgui.setCursorPosX(style.item_spacing[0]);
            drawTool(pixi.fa.mouse_pointer, button_width, button_height, .pointer);
            zgui.sameLine(.{});
            drawTool(pixi.fa.pencil_alt, button_width, button_height, .pencil);
            zgui.sameLine(.{});
            drawTool(pixi.fa.eraser, button_width, button_height, .eraser);
        }

        // Row 2
        {
            zgui.setCursorPosX(style.item_spacing[0]);
            drawTool(pixi.fa.sort_amount_up, button_width, button_height, .heightmap);
        }

        zgui.spacing();
        zgui.spacing();
        zgui.text("Colors", .{});
        zgui.separator();

        if (pixi.state.tools.current == .heightmap) {
            var height: i32 = @intCast(i32, pixi.state.colors.height);
            if (zgui.sliderInt("Height", .{
                .v = &height,
                .min = 0,
                .max = 255,
            })) {
                pixi.state.colors.height = @intCast(u8, std.math.clamp(height, 0, 255));
            }
        } else {
            var primary: [4]f32 = if (pixi.state.tools.current == .heightmap) .{} else .{
                @intToFloat(f32, pixi.state.colors.primary[0]) / 255.0,
                @intToFloat(f32, pixi.state.colors.primary[1]) / 255.0,
                @intToFloat(f32, pixi.state.colors.primary[2]) / 255.0,
                @intToFloat(f32, pixi.state.colors.primary[3]) / 255.0,
            };

            var secondary: [4]f32 = .{
                @intToFloat(f32, pixi.state.colors.secondary[0]) / 255.0,
                @intToFloat(f32, pixi.state.colors.secondary[1]) / 255.0,
                @intToFloat(f32, pixi.state.colors.secondary[2]) / 255.0,
                @intToFloat(f32, pixi.state.colors.secondary[3]) / 255.0,
            };

            if (zgui.colorButton("Primary", .{
                .col = primary,
                .w = color_width,
                .h = color_width / 2.0,
            })) {
                const color = pixi.state.colors.primary;
                pixi.state.colors.primary = pixi.state.colors.secondary;
                pixi.state.colors.secondary = color;
            }
            if (zgui.beginPopupContextItem()) {
                defer zgui.endPopup();
                if (zgui.colorPicker4("Primary", .{ .col = &primary })) {
                    pixi.state.colors.primary = .{
                        @floatToInt(u8, primary[0] * 255.0),
                        @floatToInt(u8, primary[1] * 255.0),
                        @floatToInt(u8, primary[2] * 255.0),
                        @floatToInt(u8, primary[3] * 255.0),
                    };
                }
            }
            zgui.sameLine(.{});

            if (zgui.colorButton("Secondary", .{
                .col = secondary,
                .w = color_width,
                .h = color_width / 2.0,
            })) {
                const color = pixi.state.colors.primary;
                pixi.state.colors.primary = pixi.state.colors.secondary;
                pixi.state.colors.secondary = color;
            }
            if (zgui.beginPopupContextItem()) {
                defer zgui.endPopup();
                if (zgui.colorPicker4("Secondary", .{ .col = &secondary })) {
                    pixi.state.colors.secondary = .{
                        @floatToInt(u8, secondary[0] * 255.0),
                        @floatToInt(u8, secondary[1] * 255.0),
                        @floatToInt(u8, secondary[2] * 255.0),
                        @floatToInt(u8, secondary[3] * 255.0),
                    };
                }
            }
        }
    }
    zgui.spacing();
    zgui.spacing();
    zgui.text("Palette", .{});
    zgui.sameLine(.{});
    if (zgui.smallButton(pixi.fa.sign_in_alt)) {
        pixi.state.colors.deinit();
        pixi.state.colors = pixi.Colors.load() catch unreachable;
    }
    zgui.separator();

    if (pixi.state.colors.palettes.items.len > 0) {
        const palette = pixi.state.colors.palettes.items[pixi.state.colors.selected_palette_index];
        if (zgui.beginCombo("Palette", .{ .preview_value = palette.name, .flags = .{ .height_largest = true } })) {
            defer zgui.endCombo();
            for (pixi.state.colors.palettes.items, 0..) |p, i| {
                if (zgui.selectable(p.name, .{ .selected = i == pixi.state.colors.selected_palette_index })) {
                    pixi.state.colors.selected_palette_index = i;
                }
            }
        }
        if (zgui.beginChild("PaletteColors", .{})) {
            defer zgui.endChild();
            for (palette.colors, 0..) |color, i| {
                const c: [4]f32 = .{
                    @intToFloat(f32, color[0]) / 255.0,
                    @intToFloat(f32, color[1]) / 255.0,
                    @intToFloat(f32, color[2]) / 255.0,
                    @intToFloat(f32, color[3]) / 255.0,
                };
                zgui.pushIntId(@intCast(i32, i));
                if (zgui.colorButton(palette.name, .{
                    .col = c,
                })) {
                    pixi.state.colors.primary = color;
                }
                zgui.popId();
                if (@mod(i + 1, 5) > 0 and i != palette.colors.len - 1)
                    zgui.sameLine(.{});
            }
        }
    }
}

pub fn drawTool(label: [:0]const u8, w: f32, h: f32, tool: pixi.Tool) void {
    const selected = pixi.state.tools.current == tool;
    if (selected) {
        zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.text, .c = pixi.state.style.text.toSlice() });
    } else {
        zgui.pushStyleColor4f(.{ .idx = zgui.StyleCol.text, .c = pixi.state.style.text_secondary.toSlice() });
    }
    defer zgui.popStyleColor(.{ .count = 1 });
    if (zgui.selectable(label, .{
        .selected = selected,
        .w = w,
        .h = h,
    })) {
        pixi.state.tools.set(tool);
    }
    drawTooltip(tool);
}

pub fn drawTooltip(tool: pixi.Tool) void {
    if (zgui.isItemHovered(.{})) {
        if (zgui.beginTooltip()) {
            defer zgui.endTooltip();

            const text = switch (tool) {
                .pointer => "Pointer",
                .pencil => "Pencil",
                .eraser => "Eraser",
                .animation => "Animation",
                .heightmap => "Heightmap",
            };

            zgui.text("{s}", .{text});
        }
    }
}
