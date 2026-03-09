#+vet explicit-allocators
package src

import "core:math/linalg"
import "core:log"
import "vendor:raylib/rlgl"
import "core:math"
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

                if flag, ok := ecs.get(w, e, Flagellum); ok {
                        rl.DrawTexturePro(flag_texture, 
                                frame(64, 128, flag.animation.current_frame), 
                                {trans.pos.x, trans.pos.y, cell.radius*2, cell.radius*4}, 
                                {cell.radius, cell.radius}, 
                                trans.rot*linalg.DEG_PER_RAD+90, cell.color,
                        )
                }
                rl.DrawTexturePro(cell_texture, 
                        {0, 0, f32(cell_texture.width), f32(cell_texture.height)}, 
                        {trans.pos.x, trans.pos.y, cell.radius*2, cell.radius*2}, 
                        {cell.radius, cell.radius}, 
                        trans.rot*linalg.DEG_PER_RAD, cell.color,
                )

                if ecs.has(w, e, Selected) {
                        rl.DrawPolyLines(auto_cast trans.pos, 10, cell.radius, 0, SELECT_COLOR)
                }
        }
}

draw_menu :: proc(w: ^ecs.World) {
        if im.Begin("cells") {
                all_cells := ecs.query(w, {Cell})
                im.Text(fmt.caprintf("total cells: %d", len(all_cells), allocator = w.frame_allocator))
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
