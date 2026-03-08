package src

import rl "vendor:raylib"

Animation :: struct {
        current_frame: i32,
        frame_count: i32,
        frame_time: f32, // seconds
        current_frame_time: f32,
}

animation_update :: proc(a: ^Animation, delta_time: f32) {
        a.current_frame_time += delta_time
        if a.current_frame_time >= a.frame_time {
                a.current_frame_time -= a.frame_time
                a.current_frame += 1
                if a.current_frame >= a.frame_count {
                        a.current_frame = 0
                }
        }
}

frame :: proc(frame_width, frame_hight, id: i32) -> rl.Rectangle {
        return {
                x = f32(frame_width * id),
                y = 0,
                width = f32(frame_width),
                height = f32(frame_hight),
        }
}
