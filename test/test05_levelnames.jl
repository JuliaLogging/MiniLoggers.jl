module LevelNamesTest
using MiniLoggers
using Logging: LogLevel, BelowMinLevel, Debug, Info, Warn, Error, AboveMaxLevel
using ReTest

function levelname(level::LogLevel)
    if     level == Debug          "MYDEBUG"
    elseif level == Info           "MYINFO"
    else                           "LOG"
    end
end

@testset "MiniLogger Level Names" begin
    buf = IOBuffer()
    iob = IOContext(buf, stdout)
    
    with_logger(MiniLogger(io = iob, minlevel = MiniLoggers.Debug, format = "level", levelname = levelname)) do 
        @info ""
        @debug ""
        @warn ""
    end

    s = String(take!(buf))
    @test s == "MYINFO\nMYDEBUG\nLOG\n"
end

@testset "JsonLogger Level Names" begin
    buf = IOBuffer()
    iob = IOContext(buf, stdout)
    
    with_logger(JsonLogger(io = iob, minlevel = MiniLoggers.Debug, format = "level", levelname = levelname)) do 
        @info ""
        @debug ""
        @warn ""
    end

    s = String(take!(buf))
    @test s == "{\"level\":\"MYINFO\"}\n{\"level\":\"MYDEBUG\"}\n{\"level\":\"LOG\"}\n"
end

end # module
