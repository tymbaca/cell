package src

import rl "vendor:raylib"
import "lib:ecs"

draw_cell :: proc(cell: Cell, pos: Position, selected: bool) {
	rl.DrawPoly(auto_cast pos, 8, cell.radius, 0, cell.color)
    if selected {
        rl.DrawPolyLines(auto_cast pos, 8, cell.radius, 0, SELECT_COLOR)
    }
}

draw_menu :: proc(w: ^ecs.World) {
    for e, i in ecs.query(w, {Selected, Cell, Position}) {
        pos := ecs.get(w, e, Position)
        cell := ecs.get(w, e, Cell)

        rl.GuiWindowBox()
    }
}
