#+vet explicit-allocators
package src

import "core:math"
import "core:fmt"
import im "lib:imgui"
import rl "vendor:raylib"
import "lib:ecs"

FLAG_LEN :: 5

draw_cells :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Transform, Cell}) {
                trans := ecs.get(w, e, Transform)
                cell := ecs.get(w, e, Cell)
                dir := rot_to_dir(trans.rot)

                rl.DrawPoly(auto_cast trans.pos, 8, cell.radius, (trans.rot)*math.DEG_PER_RAD, cell.color)
                if ecs.has(w, e, Selected) {
                        rl.DrawPolyLines(auto_cast trans.pos, 8, cell.radius, 0, SELECT_COLOR)
                }
                if flag, ok := ecs.get(w, e, Flagellum); ok {
                        flag_start := trans.pos - dir * cell.radius
                        rl.DrawLineV(flag_start, flag_start - dir * FLAG_LEN, cell.color)
                }
        }
}

draw_menu :: proc(w: ^ecs.World) {
        if im.Begin("cells") {
                for e, i in ecs.query(w, {Selected, Cell, Transform, Velocity}) {
                        trans := ecs.get(w, e, Transform)
                        vel := ecs.get(w, e, Velocity)
                        cell := ecs.get(w, e, Cell)

                        if im.CollapsingHeader(fmt.caprint(e.id, allocator = w.frame_allocator), {.DefaultOpen}) {
                                im.Text(fmt.caprintf("trans:  %v", trans, allocator = w.frame_allocator))
                                im.Text(fmt.caprintf("vel:  %v", vel, allocator = w.frame_allocator))
                                im.Text(fmt.caprintf("cell: %v", cell, allocator = w.frame_allocator))
                        }
                }
        }
        im.End()
}
