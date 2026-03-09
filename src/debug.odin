#+vet explicit-allocators
package src

import "lib:ecs"
import rl "vendor:raylib"

debug_system :: proc(w: ^ecs.World) {
        ctx := (^Context)(w.userdata)

        if rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.DOWN) {
                ctx.debug.bvh_draw_depth -= 1
                ctx.debug.bvh_draw_depth = max(ctx.debug.bvh_draw_depth, -2)
        }
        if rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.UP) {
                ctx.debug.bvh_draw_depth += 1
        }
}
