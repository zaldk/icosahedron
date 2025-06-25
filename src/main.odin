package elementals

import "core:fmt"
import "core:log"
import "core:mem"
import rl "vendor:raylib"
import tw "tailwind"

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
    context.logger = log.create_console_logger(log.Level.Debug, {.Level, .Time, .Short_File_Path, .Line, .Terminal_Color}, allocator = context.temp_allocator)
    // }}}

    rl.SetConfigFlags({ .WINDOW_ALWAYS_RUN, .WINDOW_RESIZABLE, .MSAA_4X_HINT })
    rl.InitWindow(800, 800, "FLOAT")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    quit := false
    for !rl.WindowShouldClose() && !quit {
        key := rl.GetKeyPressed()
        switch {
        case key == .F1: log.infof("You have pressed <F1>")
        }

        // {{{ Draw Calls
        rl.BeginDrawing(); {
            rl.ClearBackground({0,0,0,255})
            rl.DrawFPS(0,0)
        }; rl.EndDrawing()
        // }}}
        defer free_all(context.temp_allocator)
    }
}
