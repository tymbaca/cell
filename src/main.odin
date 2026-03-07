#+vet explicit-allocators
package src

import "core:mem"
import "core:math/linalg"
import "core:math/rand"
import "lib:ecs"
import rl "vendor:raylib"
import imgui_rl "lib:imgui/imgui_impl_raylib"
import imgui "lib:imgui"

SCREEN_WIDTH :: 1200
SCREEN_HEIGHT :: 800

CENTER_X :: SCREEN_WIDTH / 2
CENTER_Y :: SCREEN_HEIGHT / 2

Context :: struct {
        resistence: f32,
}

main :: proc() {
        allocator := context.allocator
        context.allocator = mem.panic_allocator()
        context.temp_allocator = mem.panic_allocator()

        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "cell")
        defer rl.CloseWindow()
        rl.SetTargetFPS(60)

        imgui.CreateContext(nil)
        defer imgui.DestroyContext(nil)
        imgui_rl.init()
        defer imgui_rl.shutdown()
        imgui_rl.build_font_atlas()

        component_types := []typeid{Position, Velocity, Cell, Selected}

        world: ecs.World
        w := &world
        ecs.init(w, component_types, context.allocator)
        defer ecs.destroy(w)

        ecs.register(w, velocity_system)
        ecs.register(w, spawn_system)
        ecs.register(w, select_system)

        ctx := Context {
                resistence = 1,
        }
        w.userdata = &ctx

        for !rl.WindowShouldClose() {
                ecs.update(w)

                imgui_rl.process_events()
                imgui_rl.new_frame()
                imgui.NewFrame()
                rl.BeginDrawing()
                rl.ClearBackground({40, 40, 60, 255})
                rl.DrawCircleGradient(CENTER_X, CENTER_Y, 300, rl.BLUE, rl.DARKBLUE)

                for e in ecs.query(w, {Position, Cell}) {
                        pos := ecs.get(w, e, Position)
                        cell := ecs.get(w, e, Cell)

                        draw_cell(cell, pos, ecs.has(w, e, Selected))
                }

                draw_menu(w)

                imgui.Render()
                imgui_rl.render_draw_data(imgui.GetDrawData())
                rl.EndDrawing()
        }
}

SELECT_COLOR :: rl.RAYWHITE

vec2 :: [2]f32

Position :: distinct vec2
Velocity :: distinct vec2
Cell :: struct {
        energy:   f32,
        capacity: f32,
        color:    rl.Color,
        radius:   f32,
}
Selected :: struct {}

select_system :: proc(w: ^ecs.World) {
        if !rl.IsMouseButtonPressed(.LEFT) {
                return
        }
        mouse := rl.GetMousePosition()

        // hold ctrl to select multiple
        if !rl.IsKeyDown(.LEFT_CONTROL) {
                for e in ecs.query(w, {Selected}) {
                        ecs.unset(w, e, Selected)
                }
        }

        for e in ecs.query(w, {Position, Cell}) {
                pos := ecs.get(w, e, Position)
                cell := ecs.get(w, e, Cell)

                if linalg.distance(auto_cast mouse, auto_cast pos) < cell.radius {
                        if ecs.has(w, e, Selected) {
                                ecs.unset(w, e, Selected)
                        } else {
                                ecs.set(w, e, Selected{})
                        }
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
                create_cell(w, auto_cast rl.GetMousePosition())
        }
}

create_cell :: proc(w: ^ecs.World, pos: Position) {
        e := ecs.create(w)
        ecs.set(w, e, pos)
        // ecs.set(w, e, Velocity{rand.float32_range(-1, 1), rand.float32_range(-1, 1)})
        ecs.set(w, e, Velocity{1, 1})
        ecs.set(w, e, Cell{
                energy = 100, 
                capacity = 100, 
                color = rl.GREEN, 
                radius = 10,
        })
}
