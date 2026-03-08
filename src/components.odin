#+vet explicit-allocators
package src

import rl "vendor:raylib"

vec2 :: [2]f32
vec4 :: [4]f32

Transform :: struct {
        pos: vec2,
        rot: f32, // radians
}
Velocity :: distinct vec2
Cell :: struct {
        energy:   f32,
        capacity: f32,
        color:    rl.Color,
        radius:   f32,
}
Selected :: struct {}
Flagellum :: struct {
        power: f32,
        max_power: f32,
        animation: Animation,
}

to_glsl_color :: proc(c: rl.Color) -> (res: vec4) {
        res.x = f32(c.x) / 255
        res.y = f32(c.y) / 255
        res.z = f32(c.z) / 255
        res.a = f32(c.a) / 255

        return res
}
