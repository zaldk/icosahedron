package elementals

import "core:fmt"
import "core:log"
import "core:mem"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"
import tw "tailwind"

FONT_SIZE :: 18

FACES := [?][3]int{
    {0,3,4},
    {0,5,3},
    {0,4,8},
    {0,11,5},
    {0,8,11},
    {1,2,6},
    {1,7,2},
    {1,6,11},
    {1,8,7},
    {1,11,8},
    {2,10,6},
    {2,7,9},
    {2,9,10},
    {3,9,4},
    {3,5,10},
    {3,10,9},
    {4,7,8},
    {4,9,7},
    {5,6,10},
    {5,11,6},
}

get_points :: proc() -> (points : [12][3]f32) {
    p :: (math.SQRT_FIVE+1)/2

    size_yz := [3]f32{ 0, 1, p } / 2
    points[0 + 0] = {  0,  1,  1 } * size_yz
    points[0 + 1] = {  0,  1, -1 } * size_yz
    points[0 + 2] = {  0, -1, -1 } * size_yz
    points[0 + 3] = {  0, -1,  1 } * size_yz

    size_zx := [3]f32{ p, 0, 1 } / 2
    points[4 + 0] = {  1,  0,  1 } * size_zx
    points[4 + 1] = { -1,  0,  1 } * size_zx
    points[4 + 2] = { -1,  0, -1 } * size_zx
    points[4 + 3] = {  1,  0, -1 } * size_zx

    size_xy := [3]f32{ 1, p, 0 } / 2
    points[8 + 0] = {  1,  1,  0 } * size_xy
    points[8 + 1] = {  1, -1,  0 } * size_xy
    points[8 + 2] = { -1, -1,  0 } * size_xy
    points[8 + 3] = { -1,  1,  0 } * size_xy

    return
}

POINTS := get_points()

main :: proc() {
    // {{{ Tracking + Temp. Allocator + Logging
    // taken from youtube.com/watch?v=dg6qogN8kIE
    tracking_allocator : mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer {
        for key, value in tracking_allocator.allocation_map {
            fmt.printfln("[%v] %v leaked %v bytes", key, value.location, value.size)
        }
        for value in tracking_allocator.bad_free_array {
            fmt.printfln("[%v] %v double free detected", value.memory, value.location)
        }
        mem.tracking_allocator_clear(&tracking_allocator)
    }
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger(log.Level.Debug, {.Level, .Time, .Short_File_Path, .Line, .Terminal_Color})
    defer log.destroy_console_logger(context.logger)
    // }}}

    rl.SetConfigFlags({ .WINDOW_ALWAYS_RUN, .WINDOW_RESIZABLE, .MSAA_4X_HINT })
    rl.InitWindow(1200, 1200, "FLOAT")
    defer rl.CloseWindow()
    rl.SetTargetFPS(144)

    CAMERA : rl.Camera3D
    CAMERA.position = { 1, 1, 1 } * 3
    CAMERA.target = { 0, 0, 0 }
    CAMERA.up = { 0, 1, 0 }
    CAMERA.fovy = 45
    CAMERA.projection = .PERSPECTIVE

    quit := false
    for !rl.WindowShouldClose() && !quit {
        rl.UpdateCamera(&CAMERA, .ORBITAL)
        rl.BeginDrawing(); {
            rl.ClearBackground({0,0,0,255})

            rl.BeginMode3D(CAMERA); {
                for f in FACES {
                    mid_point: [3]f32
                    mid_point += POINTS[f.x] / 3
                    mid_point += POINTS[f.y] / 3
                    mid_point += POINTS[f.z] / 3
                    cam_dist_vec := CAMERA.position - mid_point
                    cam_dist := linalg.length(cam_dist_vec)
                    // rl.DrawTriangle3D(POINTS[f.x], POINTS[f.y], POINTS[f.z], rl.ColorFromNormalized({ math.sqrt(1 / cam_dist), 0, 0, 0.5 }))
                    // rl.DrawTriangle3D(POINTS[f.x]*0.9, POINTS[f.y]*0.9, POINTS[f.z]*0.9, rl.ColorFromNormalized({ 0, math.sqrt(1 / cam_dist), 0, 0.5 }))
                    t := f32(0.1)
                    rl.DrawLine3D(
                        math.lerp(POINTS[f.x], mid_point, t),
                        math.lerp(POINTS[f.y], mid_point, t),
                        rl.ColorFromNormalized({ math.sqrt(1 / cam_dist), 0, 0, 1 })
                    )
                    rl.DrawLine3D(
                        math.lerp(POINTS[f.y], mid_point, t),
                        math.lerp(POINTS[f.z], mid_point, t),
                        rl.ColorFromNormalized({ math.sqrt(1 / cam_dist), 0, 0, 1 })
                    )
                    rl.DrawLine3D(
                        math.lerp(POINTS[f.z], mid_point, t),
                        math.lerp(POINTS[f.x], mid_point, t),
                        rl.ColorFromNormalized({ math.sqrt(1 / cam_dist), 0, 0, 1 })
                    )
                }
            }; rl.EndMode3D()
            for p, i in POINTS {
                screen_pos := rl.GetWorldToScreen(p, CAMERA)
                rl.DrawText(rl.TextFormat("%d", i), i32(screen_pos.x+FONT_SIZE/4), i32(screen_pos.y-FONT_SIZE), FONT_SIZE, rl.BLUE)
            }
            for f, i in FACES {
                mid_point: [3]f32
                mid_point += POINTS[f.x] / 3
                mid_point += POINTS[f.y] / 3
                mid_point += POINTS[f.z] / 3
                screen_pos := rl.GetWorldToScreen(mid_point, CAMERA)
                rl.DrawText(rl.TextFormat("%d", i), i32(screen_pos.x+FONT_SIZE/4), i32(screen_pos.y-FONT_SIZE), FONT_SIZE, rl.GREEN)
            }

            rl.DrawFPS(0,0)
        }; rl.EndDrawing()
        defer free_all(context.temp_allocator)
    }
}
