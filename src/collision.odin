#+vet explicit-allocators
package src

import "core:math/linalg"
import "lib:bvh"
import "src:collider"
import "lib:ecs"


COLLISION_PUSH_MULTIPLIER :: 10

collision_system :: proc(w: ^ecs.World) {
        tree: bvh.Node(collider.Circle, ecs.Entity)

        for e in ecs.query(w, {Cell, Transform, Velocity}) {
                cell := ecs.get(w, e, Cell)
                trans := ecs.get(w, e, Transform)
                vel := ecs.get(w, e, Velocity)

                cldr := collider.Circle{center = trans.pos, radius = cell.radius}
                bvh.insert(&tree, cldr, e, 
                        collider.calculate_bounding_circle, 
                        collider.get_circle_growth, 
                        &w.frame_arena,
                )
        }

        for col in bvh.check_collisions(&tree, collider.circles_intersect, &w.frame_arena) {
                a_trans := ecs.get(w, col.a.body, Transform)
                b_trans := ecs.get(w, col.b.body, Transform)
                a_to_b := b_trans.pos - a_trans.pos
                penetration := linalg.length(a_to_b)

                if penetration <= 0 {
                        continue
                }

                a_vel := ecs.get(w, col.a.body, Velocity)
                b_vel := ecs.get(w, col.b.body, Velocity)

                b_vel += auto_cast a_to_b * COLLISION_PUSH_MULTIPLIER * w.delta
                a_vel += auto_cast -a_to_b * COLLISION_PUSH_MULTIPLIER * w.delta

                ecs.set(w, col.a.body, a_vel)
                ecs.set(w, col.b.body, b_vel)
        }
}
