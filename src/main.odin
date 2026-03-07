package main

import "core:math/linalg"
import "lib:ecs"
import rl "vendor:raylib"
import "core:math/rand"

SCREEN_WIDTH :: 1200
SCREEN_HEIGHT :: 800

CENTER_X :: SCREEN_WIDTH / 2
CENTER_Y :: SCREEN_HEIGHT / 2

Context :: struct {
    resistence: f32,
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "cell")
	defer rl.CloseWindow()
    rl.SetTargetFPS(60)

	world: ecs.World
	w := &world
	ecs.init(w, {Position, Velocity, Cell}, context.allocator)
	defer ecs.destroy(w)

    ecs.register(w, velocity_system)
    ecs.register(w, spawn_system)
    ecs.register(w, select_system)

    ctx := Context{
        resistence = 1,
    }
    w.userdata = &ctx

    e := ecs.create(w)
    ecs.set(w, e, Position{CENTER_X, CENTER_Y})
    // ecs.set(w, e, Velocity{rand.float32_range(-1, 1), rand.float32_range(-1, 1)})
    ecs.set(w, e, Velocity{1, 1})
    ecs.set(w, e, Cell{
        energy = 100,
        capacity = 100,
        color = rl.YELLOW,
        radius = 5,
    })

	for !rl.WindowShouldClose() {
        ecs.update(w)

		rl.BeginDrawing()
		rl.ClearBackground({40, 40, 60, 255})
		rl.DrawCircleGradient(CENTER_X, CENTER_Y, 300, rl.BLUE, rl.DARKBLUE)

        for e in ecs.query(w, {Position, Cell}) {
            pos := ecs.get(w, e, Position)
            cell := ecs.get(w, e, Cell)

            draw_cell(cell, pos, ecs.has(w, e, Selected))
        }

		rl.EndDrawing()
	}
}

SELECT_COLOR :: rl.RAYWHITE

draw_cell :: proc(cell: Cell, pos: Position, selected: bool) {
    rl.DrawPoly(auto_cast pos, 8, cell.radius, 0, cell.color)
    rl.DrawPolyLines(auto_cast pos, 8, cell.radius, 0, SELECT_COLOR)
}

vec2 :: [2]f32

Position :: distinct vec2
Velocity :: distinct vec2
Cell :: struct {
	energy:   f32,
	capacity: f32,
	color:    rl.Color,
	radius:   f32,
}
Selected :: struct{}

select_system :: proc(w: ^ecs.World) {
    if !rl.IsMouseButtonPressed(.LEFT) {
        return
    }
    mouse := rl.GetMousePosition()

    for e in ecs.query(w, {Position, Cell}) {
        pos := ecs.get(w, e, Position)
        cell := ecs.get(w, e, Cell)

        // hold ctrl to select multiple
        if !rl.IsKeyDown(.LEFT_CONTROL) {
            for e in ecs.query(w, {Selected}) {
                ecs.unset(w, e, Selected)
            }
        }

        if linalg.distance(auto_cast mouse, auto_cast pos) < cell.radius {
            ecs.set(w, e, Selected{})
            break
        }
    }
}

velocity_system :: proc(w: ^ecs.World) {
    ctx := (^Context)(w.userdata)
    for e in ecs.query(w, {Position, Velocity}) {
        pos := ecs.get(w, e, Position)
        vel := ecs.get(w, e, Velocity)

        vel = vel / (1 + ctx.resistence * w.delta) 
        pos += auto_cast vel * w.delta

        ecs.set(w, e, pos)
        ecs.set(w, e, vel)
    }
}
spawn_system :: proc(w: ^ecs.World) {
    if rl.IsMouseButtonPressed(.RIGHT) {
        e := ecs.create(w)
        ecs.set(w, e, Position(rl.GetMousePosition()))
        ecs.set(w, e, Velocity{rand.float32_range(-1, 1), rand.float32_range(-1, 1)})
        ecs.set(w, e, Cell{
            energy = 100,
            capacity = 100,
            color = rl.YELLOW,
            radius = 5,
        })
    }
}
