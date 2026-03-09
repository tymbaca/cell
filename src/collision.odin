#+vet explicit-allocators
package src

import "lib:bvh"
import "src:collider"
import "lib:ecs"



collision_system :: proc(w: ^ecs.World) {
        tree: bvh.Node(collider.Circle, ecs.Entity)

        for e in ecs.query(w, {Cell, Transform, Velocity}) {
                cell := ecs.get(w, e, Cell)
                trans := ecs.get(w, e, Transform)
                vel := ecs.get(w, e, Velocity)

                bvh.insert(&tree, cell.collider, e, 
                        collider.calculate_bounding_circle, 
                        collider.get_circle_growth, 
                        &w.frame_arena,
                )
        }

        bvh.check_collisions(&tree, collider.circles_intersect, )
}
