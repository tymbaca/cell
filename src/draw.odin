#+vet explicit-allocators
package src

import "core:math/linalg"
import "lib:bvh"
import "src:collider"
import "core:fmt"
import im "lib:imgui"
import rl "vendor:raylib"
import "lib:ecs"

FLAG_LEN :: 5

draw_dish :: proc(w: ^ecs.World, center: vec2, radius: f32) {
        rl.DrawCircleGradient(i32(center.x), i32(center.y), radius, rl.GRAY, rl.DARKGRAY)
}

draw_cells :: proc(w: ^ecs.World, shader: rl.Shader, cell_texture, flag_texture: rl.Texture2D) {
        rl.BeginShaderMode(shader)
        defer rl.EndShaderMode()

        for e in ecs.query(w, {Transform, Cell}) {
                trans := ecs.get(w, e, Transform)
                cell := ecs.get(w, e, Cell)
                dir := rot_to_dir(trans.rot)

                tint := rl.ColorLerp(cell.color, rl.GREEN, 0.5)

                if flag, ok := ecs.get(w, e, Flagellum); ok {
                        rl.DrawTexturePro(flag_texture, 
                                frame(64, 128, flag.animation.current_frame), 
                                {trans.pos.x, trans.pos.y, cell.radius*2, cell.radius*4}, 
                                {cell.radius, cell.radius}, 
                                trans.rot*linalg.DEG_PER_RAD+90, tint,
                        )
                }
                rl.DrawTexturePro(cell_texture, 
                        {0, 0, f32(cell_texture.width), f32(cell_texture.height)}, 
                        {trans.pos.x, trans.pos.y, cell.radius*2, cell.radius*2}, 
                        {cell.radius, cell.radius}, 
                        trans.rot*linalg.DEG_PER_RAD, tint,
                )

                if ecs.has(w, e, Selected) {
                        rl.DrawPolyLines(auto_cast trans.pos, 10, cell.radius, 0, SELECT_COLOR)
                }
        }

        for e in ecs.query(w, {Link}) {
                link := ecs.get(w, e, Link)
                a_trans := ecs.get(w, link.a, Transform)
                b_trans := ecs.get(w, link.b, Transform)
                // a_cell := ecs.get(w, link.a, Cell)
                // b_cell := ecs.get(w, link.b, Cell)
                // a_vel := ecs.get(w, link.a, Velocity)
                // b_vel := ecs.get(w, link.b, Velocity)

                rl.DrawLineV(a_trans.pos, b_trans.pos, rl.RAYWHITE)
        }
}

draw_menu :: proc(w: ^ecs.World) {
        ctx := (^Context)(w.userdata)

        if im.Begin("context") {
                im.Text(fmt.caprintf("edit_mode: %s", ctx.edit_mode, allocator = w.frame_allocator))
        }
        im.End()

        if im.Begin("cells") {
                all_cells := ecs.query(w, {Cell})
                im.Text(fmt.caprintf("total cells: %d", len(all_cells), allocator = w.frame_allocator))
                im.Text(fmt.caprintf("bvh depth draw: %d", ctx.debug.bvh_draw_depth, allocator = w.frame_allocator))
                for e, i in ecs.query(w, {Selected, Cell, Transform, Velocity}) {
                        trans := ecs.get(w, e, Transform)
                        vel := ecs.get(w, e, Velocity)
                        cell := ecs.get(w, e, Cell)
                        flag := ecs.get(w, e, Flagellum)
                        drag := ecs.get(w, e, Draggable)

                        if im.CollapsingHeader(fmt.caprint(e.id, allocator = w.frame_allocator), {.DefaultOpen}) {
                                im.Text(fmt.caprintf("trans:  %v", trans, allocator = w.frame_allocator))
                                im.Text(fmt.caprintf("vel:  %v", vel, allocator = w.frame_allocator))
                                im.Text(fmt.caprintf("cell: %v", cell, allocator = w.frame_allocator))
                                im.Text(fmt.caprintf("flag: %v", flag, allocator = w.frame_allocator))
                                im.Text(fmt.caprintf("drag: %v", drag, allocator = w.frame_allocator))
                        }
                }
        }
        im.End()
}

draw_bvh :: proc(node: ^bvh.Node(collider.Circle, ecs.Entity), color: rl.Color, draw := -1, depth := 0) {
        if node == nil {
                return
        }

        if draw != -2 {
                if draw == -1 || draw == depth {
                        rl.DrawCircleLinesV(auto_cast node.volume.center, node.volume.radius, color)
                        rl.DrawText(rl.TextFormat("%i", depth), i32(node.volume.center.x), i32(node.volume.center.y), i32(node.volume.radius), rl.WHITE)
                }
        }

        draw_bvh(node.left, color, draw = draw, depth = depth + 1)
        draw_bvh(node.right, color, draw = draw, depth = depth + 1)
}

draw_lights :: proc(w: ^ecs.World) {
        rl.BeginBlendMode(.ADDITIVE)
        defer rl.EndBlendMode()
        for e in ecs.query(w, {Light, Transform}) {
                trans := ecs.get(w, e, Transform)
                light := ecs.get(w, e, Light)
                rl.DrawCircleGradient(i32(trans.pos.x), i32(trans.pos.y), light.radius, 
                        rl.ColorLerp({255, 255, 255, 0}, rl.WHITE, light.power), 
                        rl.ColorLerp({255, 255, 255, 0}, rl.WHITE, 0),
                )
        }
}

to_glsl_color :: proc(c: rl.Color) -> (res: vec4) {
        res.x = f32(c.x) / 255
        res.y = f32(c.y) / 255
        res.z = f32(c.z) / 255
        res.a = f32(c.a) / 255

        return res
}

from_glsl_color :: proc(c: vec4) -> (res: rl.Color) {
        res.x = u8(c.x * 255)
        res.y = u8(c.y * 255)
        res.z = u8(c.z * 255)
        res.a = u8(c.a * 255)

        return res
}
