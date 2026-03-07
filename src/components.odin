#+vet explicit-allocators
package src

import rl "vendor:raylib"

vec2 :: [2]f32

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
}
