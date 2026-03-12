#+vet explicit-allocators
package src

import "core:time"
import "core:math"
import "core:math/rand"
import "lib:ecs"
import rl "vendor:raylib"
import "core:math/noise"

Link :: struct {
        a: ecs.Entity,
        b: ecs.Entity,
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

get_sibling :: proc(link: Link, me: ecs.Entity) -> ecs.Entity {
        if link.a == me {
                return link.b
        } 

        if link.b == me {
                return link.a
        } 

        panic("unreachable")
}
