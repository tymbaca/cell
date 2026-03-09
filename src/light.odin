#+vet explicit-allocators
package src

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
                        power = 1.0,
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

light_system :: proc(w: ^ecs.World) {
        // for e in ecs.query(w, )
}
