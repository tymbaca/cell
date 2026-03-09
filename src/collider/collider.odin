package collider

import "core:testing"
import "core:math/linalg"

Circle :: struct {
        center: [2]f32,
        radius: f32,
}

calculate_bounding_circle :: proc(c1, c2: Circle) -> Circle {
        dist := linalg.distance(c1.center, c2.center)

        if dist + c1.radius <= c2.radius do return c2
        if dist + c2.radius <= c1.radius do return c1

        radius := (c1.radius + c2.radius + dist) / 2
        center := c1.center + (c2.center - c1.center) * (radius - c1.radius) / dist

        return {center, radius}
}

@(test)
calculate_bounding_circle_test :: proc(t: ^testing.T) {
        testing.expect_value(t, calculate_bounding_circle({{10, 10}, 5}, {{10, 10}, 3}), Circle{{10, 10}, 5})
        testing.expect_value(t, calculate_bounding_circle({{10, 10}, 5}, {{10, 10}, 5}), Circle{{10, 10}, 5})
        testing.expect_value(t, calculate_bounding_circle({{10, 10}, 5}, {{10, 10}, 5.7}), Circle{{10, 10}, 5.7})
        testing.expect_value(t, calculate_bounding_circle({{0, 0}, 5}, {{10, 0}, 5}), Circle{{5, 0}, 10})
        testing.expect_value(t, calculate_bounding_circle({{-5, 0}, 0}, {{5, 0}, 0}), Circle{{0, 0}, 5}) // dots
}

get_circle_growth :: proc(into, v: Circle) -> f32 {
        return calculate_bounding_circle(into, v).radius - into.radius
}

circles_intersect :: proc(a, b: Circle) -> bool {
        return linalg.distance(a.center, b.center) < a.radius + b.radius
}
