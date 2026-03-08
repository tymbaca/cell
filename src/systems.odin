#+vet explicit-allocators
package src

import "core:math/rand"
import "core:math"
import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"
import imgui "lib:imgui"

SELECT_COLOR :: rl.RAYWHITE

select_system :: proc(w: ^ecs.World) {
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

                ecs.set(w, e, trans)
                ecs.set(w, e, vel)
        }
}

flagellum_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Transform, Velocity, Cell, Flagellum}) {
                trans := ecs.get(w, e, Transform)
                vel := ecs.get(w, e, Velocity)
                cell := ecs.get(w, e, Cell)
                flag := ecs.get(w, e, Flagellum)

                add_vel := rot_to_dir(trans.rot) * flag.power * w.delta
                vel += auto_cast add_vel

                trans.rot += rand.float32_range(-10, 10) * w.delta

                animation_update(&flag.animation, w.delta)

                ecs.set(w, e, trans)
                ecs.set(w, e, vel)
                ecs.set(w, e, cell)
                ecs.set(w, e, flag)
        }
}

rot_to_dir :: proc(rot: f32) -> vec2 {
        return {math.cos(rot), math.sin(rot)}
}

debug_spawn_system :: proc(w: ^ecs.World) {
        if rl.IsMouseButtonPressed(.RIGHT) {
                debug_create_cell(w, {pos = auto_cast rl.GetMousePosition(), rot = rand.float32_range(0, 2*math.PI)})
        }
}

DEFAULT_SPEED :: 100

debug_create_cell :: proc(w: ^ecs.World, trans: Transform) {
        e := ecs.create(w)
        ecs.set(w, e, trans)
        // ecs.set(w, e, Velocity{rand.float32_range(-1, 1), rand.float32_range(-1, 1)})
        ecs.set(w, e, Velocity(rl.GetMouseDelta()))
        ecs.set(w, e, Cell{
                energy = 100, 
                capacity = 100, 
                color = choose([]rl.Color{rl.ORANGE, rl.WHITE, rl.YELLOW, rl.GREEN, rl.BLUE, rl.RED, rl.PURPLE, rl.PINK}),
                radius = rand.float32_range(5, 20),
        })
        power := rand.float32_range(10, 60)
        ecs.set(w, e, Flagellum{
                power = power,
                max_power = power,
                animation = {
                        frame_count = 4,
                        frame_time = 1 / power,
                },
        })
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
