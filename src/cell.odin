#+vet explicit-allocators
package src

import "core:time"
import "core:math"
import "core:math/rand"
import "lib:ecs"
import rl "vendor:raylib"
import "core:math/noise"

Cell :: struct {
        energy:   f32,
        starving_started: Maybe(time.Tick),
        max_energy: f32,
        color:    rl.Color,
        radius:   f32,
}

Flagellum :: struct {
        power: f32,
        max_power: f32,
        animation: Animation,
}

Random_Rotation :: struct {
        seed:  i64,
        coord: [2]f64,
        mul:   f32,
}

Link :: struct {
        a: ecs.Entity,
        b: ecs.Entity,
}

Photosynthesis :: struct {}

debug_spawn_system :: proc(w: ^ecs.World) {
        if ctx(w).edit_mode != .Cells {
                return
        }

        if rl.IsMouseButtonDown(.RIGHT) {
                debug_create_cell(w, {pos = auto_cast rl.GetMousePosition(), rot = rand.float32_range(0, 2*math.PI)})
        }
}

DEFAULT_SPEED :: 100

debug_create_cell :: proc(w: ^ecs.World, trans: Transform) {
        e := ecs.create(w)
        ecs.set(w, e, trans)
        ecs.set(w, e, Velocity(rl.GetMouseDelta()))
        radius := rand.float32_range(5, 20)
        ecs.set(w, e, Cell{
                energy = 100, 
                max_energy = 100, 
                color = choose([]rl.Color{rl.ORANGE, rl.WHITE, rl.YELLOW, rl.GREEN, rl.BLUE, rl.RED, rl.PURPLE, rl.PINK}),
                radius = radius,
        })
        power := rand.float32_range(10, 60)
        ecs.set(w, e, Flagellum{
                power = power,
                max_power = power,
                animation = {
                        frame_count = 4,
                        frame_time = 2 / power,
                },
        })
        ecs.set(w, e, Random_Rotation{
                seed = rand.int63(),
                mul = 1,
        })
        ecs.set(w, e, Draggable{
                dragging = false,
                radius = radius,
        })
        ecs.set(w, e, Photosynthesis{})
}

CELL_RADIUS_MIN :: 6
CELL_RADIUS_PER_ENERGY :: 0.05
STARVE_BEFORE_DEATH :: 5 * time.Second

cell_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Cell, Transform}) {
                cell := ecs.get(w, e, Cell)
                trans := ecs.get(w, e, Transform)

                // update radius
                cell.radius = CELL_RADIUS_MIN + (cell.energy * CELL_RADIUS_PER_ENERGY)
                if drag, ok := ecs.get(w, e, Draggable); ok {
                        drag.radius = cell.radius
                        ecs.set(w, e, drag)
                }

                // starvation
                if cell.energy > 0 {
                        cell.starving_started = nil
                } else {
                        if starvation_started, ok := cell.starving_started.?; ok {
                                // starvation already started, check if time to die
                                if time.tick_since(starvation_started) > STARVE_BEFORE_DEATH {
                                        kill_cell(w, e)
                                        continue
                                }
                        } else {
                                // starvation starts here
                                cell.starving_started = time.tick_now()
                        }
                }

                ecs.set(w, e, cell)
        }
}

kill_cell :: proc(w: ^ecs.World, e: ecs.Entity) {
        ecs.kill(w, e)
}

FLAGELLUM_ENERGY_COST :: 0.5

flagellum_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Transform, Velocity, Cell, Flagellum}) {
                trans := ecs.get(w, e, Transform)
                vel := ecs.get(w, e, Velocity)
                cell := ecs.get(w, e, Cell)
                flag := ecs.get(w, e, Flagellum)

                if cell.energy <= 0 {
                        continue
                }

                power := flag.power * w.delta
                cell.energy -= power * FLAGELLUM_ENERGY_COST

                add_vel := rot_to_dir(trans.rot) * power * 10
                add_vel /= cell.radius
                vel += auto_cast add_vel

                animation_update(&flag.animation, w.delta)

                if rr, ok := ecs.get(w, e, Random_Rotation); ok {
                        rr.coord.x += f64(w.delta)
                        val := noise.noise_2d(rr.seed, rr.coord)
                        val = val * 2 - 1 // [0, 1] -> [-1, 1]
                        val *= rr.mul * w.delta
                        trans.rot += val
                        ecs.set(w, e, rr)
                }

                ecs.set(w, e, trans)
                ecs.set(w, e, vel)
                ecs.set(w, e, cell)
                ecs.set(w, e, flag)
        }
}

LINK_PULL_MULTIPLIER :: 2

debug_link_create_system :: proc(w: ^ecs.World) {
        q := ecs.query(w, {Selected})
        if len(q) == 2 && rl.IsKeyPressed(.L) {
                link_entity := ecs.create(w)
                ecs.set(w, link_entity, Link{a = q[0], b = q[1]})
        }
}

link_system :: proc(w: ^ecs.World) {
        for e in ecs.query(w, {Link}) {
                link := ecs.get(w, e, Link)
                a_trans := ecs.get(w, link.a, Transform)
                b_trans := ecs.get(w, link.b, Transform)
                a_cell := ecs.get(w, link.a, Cell)
                b_cell := ecs.get(w, link.b, Cell)
                a_vel := ecs.get(w, link.a, Velocity)
                b_vel := ecs.get(w, link.b, Velocity)

                a_to_b := b_trans.pos - a_trans.pos

                a_vel += auto_cast  a_to_b * LINK_PULL_MULTIPLIER * w.delta
                b_vel += auto_cast -a_to_b * LINK_PULL_MULTIPLIER * w.delta

                ecs.set(w, link.a, a_vel)
                ecs.set(w, link.b, b_vel)
        }
}
