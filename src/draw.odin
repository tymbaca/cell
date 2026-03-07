#+vet explicit-allocators
package src

import "core:fmt"
import im "lib:imgui"
import rl "vendor:raylib"
import "lib:ecs"

draw_cell :: proc(cell: Cell, pos: Position, selected: bool) {
        rl.DrawPoly(auto_cast pos, 8, cell.radius, 0, cell.color)
        if selected {
                rl.DrawPolyLines(auto_cast pos, 8, cell.radius, 0, SELECT_COLOR)
        }
}

draw_menu :: proc(w: ^ecs.World) {
        if im.Begin("cells") {
                for e, i in ecs.query(w, {Selected, Cell, Position, Velocity}) {
                        pos := ecs.get(w, e, Position)
                        vel := ecs.get(w, e, Velocity)
                        cell := ecs.get(w, e, Cell)

                        if im.Begin(fmt.caprint(e.id, w.)) {
                                im.Text("%s")
                        }
                        im.End()
                }
        }
        im.End()
}
