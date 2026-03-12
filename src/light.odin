#+vet explicit-allocators
package src

import "core:log"
import "lib:bvh"
import "src:collider"
import "core:math/linalg"
import rl "vendor:raylib"
import "lib:ecs"

Light :: struct {
        radius: f32,
        power:  f32, // [0.0, 1.0]
}

Not_Ready :: struct {}
Ready :: struct {}

create_light_system :: proc(w: ^ecs.World) {
        if ctx(w).edit_mode != .Light {
                return
        }

        mouse := rl.GetMousePosition()
        
        if rl.IsMouseButtonPressed(.RIGHT) {
                e := ecs.create(w)
                ecs.set(w, e, Light{
                        power = 0.5,
                })
                ecs.set(w, e, Transform{pos = mouse})
                ecs.set(w, e, Velocity{})
                ecs.set(w, e, Not_Ready{})
        }

        if rl.IsMouseButtonDown(.RIGHT) {
                for e in ecs.query(w, {Light, Not_Ready}) {
                        trans := ecs.get(w, e, Transform)
                        light := ecs.get(w, e, Light)
                        light.radius = linalg.distance(trans.pos, mouse)

                        light.power += rl.GetMouseWheelMove() * 0.05
                        light.power = rl.Clamp(light.power, 0, 1)

                        ecs.set(w, e, light)
                }
        }

        if rl.IsMouseButtonReleased(.RIGHT) {
                for e in ecs.query(w, {Light, Not_Ready}) {
                        light := ecs.get(w, e, Light)
                        ecs.set(w, e, Draggable{
                                radius = light.radius,
                        })
                        ecs.unset(w, e, Not_Ready)
                        ecs.set(w, e, Ready{})
                }
        }
}

PHOTOSYNTHESIS_MULTIPLIER :: 100

light_system :: proc(w: ^ecs.World) {
        light_bvh: bvh.Node(collider.Circle, ecs.Entity)
        for e in ecs.query(w, {Transform, Light}) {
                light := ecs.get(w, e, Light)
                trans := ecs.get(w, e, Transform)

                cldr := collider.Circle{center = trans.pos, radius = light.radius}
                bvh.insert(&light_bvh, cldr, e, 
                        collider.calculate_bounding_circle, 
                        collider.get_circle_growth, 
                        &w.frame_arena,
                )
        }

        collisions := bvh.check_collisions_with(&light_bvh, &ctx(w).bvh, collider.circles_intersect, &w.frame_arena)
        for col in collisions {
                light_entity := col.a.body
                cell_entity := col.b.body

                if !ecs.has(w, cell_entity, Photosynthesis) {
                        continue
                }

                light_trans := ecs.get(w, light_entity, Transform)
                light := ecs.get(w, light_entity, Light)
                cell_trans := ecs.get(w, cell_entity, Transform)
                cell := ecs.get(w, cell_entity, Cell)

                cell.energy += (light.power * PHOTOSYNTHESIS_MULTIPLIER * w.delta) // TODO: smooth out
                if cell.energy > cell.max_energy {
                        cell.energy = cell.max_energy
                }

                ecs.set(w, cell_entity, cell)
        }
}
