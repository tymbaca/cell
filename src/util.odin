#+vet explicit-allocators
package src

import "lib:ecs"

Pair :: struct($A, $B: typeid) {
        a: A,
        b: B,
}

find_all :: proc(w: ^ecs.World, has: []typeid, filter: proc(userdata: $U, cmp: $T) -> bool, userdata: U) -> []Pair(T, ecs.Entity) {
        result := make([dynamic]Pair(T, ecs.Entity), allocator = w.frame_allocator)

        for e in ecs.query(w, has) {
                cmp, ok := ecs.get(w, e, T)
                if !ok {
                        continue
                }
                
                if filter(userdata, cmp) {
                        append(&result, Pair(T, ecs.Entity){a = cmp, b = e})
                }
        }

        return result[:]
}

find_one :: proc(w: ^ecs.World, has: []typeid, filter: proc(userdata: $U, cmp: $T) -> bool, userdata: U) -> (T, ecs.Entity, bool) {
        for e in ecs.query(w, has) {
                cmp, ok := ecs.get(w, e, T)
                if !ok {
                        continue
                }
                
                if filter(userdata, cmp) {
                        return cmp, e, true
                }
        }

        return {}, {}, false
}
