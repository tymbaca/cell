#+vet explicit-allocators
package src

import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"

Draggable :: struct {
        dragging: bool,
        radius:   f32,
}

DRAG_MULTIPLIER :: 5

draggable_system :: proc(w: ^ecs.World) {
        mouse := rl.GetMousePosition()

        if rl.IsMouseButtonReleased(.LEFT) {
                for e in ecs.query(w, {Draggable}) {
                        drag := ecs.get(w, e, Draggable)
                        drag.dragging = false
                        ecs.set(w, e, drag)
                }
        }
        
        filter: []typeid
        switch ctx(w).edit_mode {
        case .Light:
                filter = []typeid{Draggable, Transform, Velocity, Light}
        case .Cells:
                filter = []typeid{Draggable, Transform, Velocity, Cell}
        case .None:
                filter = []typeid{Draggable, Transform, Velocity}
        }

        if rl.IsMouseButtonPressed(.LEFT) {
                for e in ecs.query(w, filter) {
                        trans := ecs.get(w, e, Transform)
                        drag := ecs.get(w, e, Draggable)

                        if linalg.distance(trans.pos, mouse) < drag.radius {
                                drag.dragging = true
                                ecs.set(w, e, drag)
                                break
                        }
                }
        }

        for e in ecs.query(w, filter) {
                drag := ecs.get(w, e, Draggable)
                vel := ecs.get(w, e, Velocity)
                trans := ecs.get(w, e, Transform)

                if drag.dragging {
                        to_mouse := mouse - auto_cast trans.pos
                        vel += auto_cast to_mouse * DRAG_MULTIPLIER * w.delta
                }

                ecs.set(w, e, vel)
        }
}
