#+vet explicit-allocators
package src

import "base:runtime"
import "core:log"
import "core:mem"
import "lib:ecs"
import rl "vendor:raylib"
import imgui_rl "lib:imgui/imgui_impl_raylib"
import imgui "lib:imgui"

SCREEN_WIDTH :: 1200
SCREEN_HEIGHT :: 800

CENTER_X :: SCREEN_WIDTH / 2
CENTER_Y :: SCREEN_HEIGHT / 2
CENTER :: vec2{CENTER_X, CENTER_Y}

Context :: struct {
        resistence: f32,
        dish_radius: f32,
}

main :: proc() {
        rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "cell")
        defer rl.CloseWindow()
        rl.SetTargetFPS(60)
        
        cell_texture := rl.LoadTexture("resources/cell.png")
        flag_texture := rl.LoadTexture("resources/flag.png")
        cell_shader := rl.LoadShader("src/shader/cell.vert.glsl", "src/shader/cell.frag.glsl")

        imgui.CreateContext(nil)
        defer imgui.DestroyContext(nil)
        imgui_rl.init()
        defer imgui_rl.shutdown()
        imgui_rl.build_font_atlas()

        allocator := context.allocator
        world: ecs.World
        w := &world
        ecs.init(w, {Transform, Velocity, Cell, Flagellum, Random_Rotation, Selected, Draggable}, allocator)
        defer ecs.destroy(w)

        ecs.register(w, velocity_system)
        ecs.register(w, debug_spawn_system)
        ecs.register(w, cell_system)
        ecs.register(w, collision_system)
        ecs.register(w, flagellum_system)
        ecs.register(w, select_system)
        ecs.register(w, draggable_system)

        context.allocator = mem.panic_allocator()
        context.temp_allocator = w.frame_allocator
        context.logger = log.create_console_logger(.Debug, allocator = allocator)

        ctx := Context {
                resistence = 1,
                dish_radius = 300,
        }
        w.userdata = &ctx

        for !rl.WindowShouldClose() {
                ecs.update(w)

                imgui_rl.process_events()
                imgui_rl.new_frame()
                imgui.NewFrame()
                rl.BeginDrawing()
                rl.ClearBackground({40, 40, 60, 255})

                rl.DrawFPS(10, 10)
                draw_dish(w, {CENTER_X, CENTER_Y}, ctx.dish_radius)
                draw_cells(w, cell_shader, cell_texture, flag_texture)
                draw_menu(w)

                imgui.Render()
                imgui_rl.render_draw_data(imgui.GetDrawData())
                rl.EndDrawing()
        }
}
