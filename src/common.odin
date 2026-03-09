#+vet explicit-allocators
package src

import "core:math/noise"
import "core:math/rand"
import "core:math"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"
import imgui "lib:imgui"

SELECT_COLOR :: rl.RAYWHITE

vec2 :: [2]f32
vec4 :: [4]f32

Transform :: struct {
        pos: vec2,
        rot: f32, // radians
}

Velocity :: distinct vec2


Selected :: struct {}

edit_mode_system :: proc(w: ^ecs.World) {
        #partial switch rl.GetKeyPressed() {
        case .ONE:
                ctx(w).edit_mode = .Cells
        case .TWO:
                ctx(w).edit_mode = .Light
        case .ZERO:
                ctx(w).edit_mode = .None
        }
}

cell_select_system :: proc(w: ^ecs.World) {
        if ctx(w).edit_mode != .Cells {
                return
        }

        if !is_mouse_focused() {
                return
        }

        if !rl.IsMouseButtonPressed(.LEFT) {
                return
        }

        // hold ctrl to select multiple
        if !rl.IsKeyDown(.LEFT_CONTROL) {
                for e in ecs.query(w, {Selected}) {
                        ecs.unset(w, e, Selected)
                }
        }

        for e in ecs.query(w, {Transform, Cell}) {
                trans := ecs.get(w, e, Transform)
                cell := ecs.get(w, e, Cell)

                if linalg.distance(auto_cast rl.GetMousePosition(), auto_cast trans.pos) < cell.radius {
                        if ecs.has(w, e, Selected) {
                                ecs.unset(w, e, Selected)
                        } else {
                                ecs.set(w, e, Selected{})
                        }
                        break
                }
        }
}

velocity_system :: proc(w: ^ecs.World) {
        ctx := (^Context)(w.userdata)
        for e in ecs.query(w, {Transform, Velocity}) {
                trans := ecs.get(w, e, Transform)
                vel := ecs.get(w, e, Velocity)

                vel = vel / (1 + ctx.resistence * w.delta)
                trans.pos += auto_cast vel * w.delta

                to_center := CENTER - trans.pos
                dist_from_center := linalg.length(to_center)
                if cell, ok := ecs.get(w, e, Cell); ok {
                        dist_from_center += cell.radius
                }
                if dist_from_center > ctx.dish_radius && faces_out_of_dish(auto_cast vel, auto_cast to_center) {
                        vel = linalg.reflect(vel, auto_cast linalg.normalize(to_center))
                        pushback := linalg.normalize(to_center) * (dist_from_center - ctx.dish_radius) * w.delta * 100
                        vel += Velocity(pushback)
                }

                ecs.set(w, e, trans)
                ecs.set(w, e, vel)
        }
}

faces_out_of_dish :: proc(vel: vec2, edge_normal: vec2) -> bool {
        if linalg.length(vel) == 0 {
                return false
        }

        if linalg.dot(linalg.normalize(vel), linalg.normalize(edge_normal)) < 0 {
                return true
        }

        return false
}

rot_to_dir :: proc(rot: f32) -> vec2 {
        return {math.cos(rot), math.sin(rot)}
}

is_mouse_focused :: proc() -> bool {
        io := imgui.GetIO()

        if io.WantCaptureMouse {
                return false
        }

        return true
}


choose :: proc(s: $T/[]$E) -> E {
        return s[rand.int_range(0, len(s))]
}
