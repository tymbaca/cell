#+vet explicit-allocators
package src

import "core:log"
import "core:math"
import "core:math/noise"
import "core:math/rand"
import "core:time"
import "lib:ecs"
import rl "vendor:raylib"

Cell :: struct {
	energy:           f32,
	starving_started: Maybe(time.Tick),
	max_energy:       f32,
	split_at:         f32, // 0 < split_at < max_energy
	split_config:     Split_Config,
	color:            rl.Color,
	radius:           f32,
}

Split_Config :: struct {}

Flagellum :: struct {
	power:     f32,
	max_power: f32,
	animation: Animation,
}

Random_Rotation :: struct {
	seed:  i64,
	coord: [2]f64,
	mul:   f32,
}

Photosynthesis :: struct {}

debug_spawn_system :: proc(w: ^ecs.World) {
	if ctx(w).edit_mode != .Cells {
		return
	}

	if rl.IsMouseButtonDown(.RIGHT) {
		debug_create_cell(
			w,
			{pos = auto_cast rl.GetMousePosition(), rot = rand.float32_range(0, 2 * math.PI)},
		)
	}
}

DEFAULT_SPEED :: 100

debug_create_cell :: proc(w: ^ecs.World, trans: Transform) {
	e := ecs.create(w)
	ecs.set(w, e, trans)
	ecs.set(w, e, Velocity(rl.GetMouseDelta()))
	radius := rand.float32_range(5, 20)
	ecs.set(
		w,
		e,
		Cell {
			energy = 80,
			max_energy = 100,
			split_at = 95,
			color = choose([]rl.Color {rl.ORANGE, rl.WHITE, rl.YELLOW, rl.GREEN, rl.BLUE, rl.RED, rl.PURPLE, rl.PINK}),
			radius = radius,
		},
	)
	power := rand.float32_range(10, 60)
	ecs.set(
		w,
		e,
		Flagellum {
			power = power,
			max_power = power,
			animation = {frame_count = 4, frame_time = 2 / power},
		},
	)
	ecs.set(w, e, Random_Rotation{seed = rand.int63(), mul = 1})
	ecs.set(w, e, Draggable{dragging = false, radius = radius})
	ecs.set(w, e, Photosynthesis{})
}

CELL_RADIUS_MIN :: 6
CELL_RADIUS_PER_ENERGY :: 0.05
STARVE_BEFORE_DEATH :: 5 * time.Second

cell_system :: proc(w: ^ecs.World) {
	for e in ecs.query(w, {Cell, Transform}) {
		cell := ecs.get(w, e, Cell)
		trans := ecs.get(w, e, Transform)

		// update radius
		cell.radius = CELL_RADIUS_MIN + (cell.energy * CELL_RADIUS_PER_ENERGY)
		if drag, ok := ecs.get(w, e, Draggable); ok {
			drag.radius = cell.radius
			ecs.set(w, e, drag)
		}

		// starvation
		if cell.energy > 0 {
			cell.starving_started = nil
		} else {
			if starvation_started, ok := cell.starving_started.?; ok {
				// starvation already started, check if time to die
				if time.tick_since(starvation_started) > STARVE_BEFORE_DEATH {
					kill_cell(w, e)
					continue
				}
			} else {
				// starvation starts here
				cell.starving_started = time.tick_now()
			}
		}

		// split
		if cell.energy >= cell.split_at {
			cell_split(w, e, cell)
                        continue
		}

		ecs.set(w, e, cell)
	}
}

kill_cell :: proc(w: ^ecs.World, e: ecs.Entity) {
	ecs.kill(w, e)
}

FLAGELLUM_ENERGY_COST :: 0.5

flagellum_system :: proc(w: ^ecs.World) {
	for e in ecs.query(w, {Transform, Velocity, Cell, Flagellum}) {
		trans := ecs.get(w, e, Transform)
		vel := ecs.get(w, e, Velocity)
		cell := ecs.get(w, e, Cell)
		flag := ecs.get(w, e, Flagellum)

		if cell.energy <= 0 {
			continue
		}

		power := flag.power * w.delta
		cell.energy -= power * FLAGELLUM_ENERGY_COST

		add_vel := rot_to_dir(trans.rot) * power * 10
		add_vel /= cell.radius
		vel += auto_cast add_vel

		animation_update(&flag.animation, w.delta)

		if rr, ok := ecs.get(w, e, Random_Rotation); ok {
			rr.coord.x += f64(w.delta)
			val := noise.noise_2d(rr.seed, rr.coord)
			val = val * 2 - 1 // [0, 1] -> [-1, 1]
			val *= rr.mul * w.delta
			trans.rot += val
			ecs.set(w, e, rr)
		}

		ecs.set(w, e, trans)
		ecs.set(w, e, vel)
		ecs.set(w, e, cell)
		ecs.set(w, e, flag)
	}
}

SPLIT_PUSH :: 25
SPLIT_ENERGY_MULTIPLIER :: 0.3

cell_split :: proc(w: ^ecs.World, e: ecs.Entity, cell: Cell) {
        cell := cell
        trans := ecs.get(w, e, Transform)
        vel := ecs.get(w, e, Velocity)

        cell.energy *= SPLIT_ENERGY_MULTIPLIER

        new_e := ecs.create(w)
        ecs.set(w, new_e, cell)
        ecs.set(w, new_e, trans)
        ecs.set(w, new_e, vel + auto_cast rot_to_dir(trans.rot)*SPLIT_PUSH)
        ecs.set(w, new_e, ecs.get(w, e, Photosynthesis))
        ecs.set(w, new_e, ecs.get(w, e, Draggable))
        ecs.set(w, new_e, ecs.get(w, e, Flagellum))
        rand_rot := ecs.get(w, e, Random_Rotation)
        rand_rot.seed = rand.int63()
        ecs.set(w, new_e, rand_rot)

        ecs.set(w, e, cell)
        ecs.set(w, e, vel - auto_cast rot_to_dir(trans.rot)*SPLIT_PUSH)


	// filter := proc(target: ecs.Entity, l: Link) -> bool {
	// 	return l.a == target || l.b == target
	// }
	//
	// for link in find_all(w, {Link}, filter, e) {
	// }
}
