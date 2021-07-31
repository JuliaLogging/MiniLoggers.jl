module LoggerFormatTest

using MiniLoggers
using ReTest

@testset "basic format" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, minlevel = MiniLoggers.Debug,
                        format = "{datetime}:{level}:{module}:{basename}:{filepath}:{line}:{group}:{module}:{id}:{message}")
    with_logger(logger) do
        @info "foo"
        s = String(take!(io))
        @test !contains(s, "datetime")
        @test !contains(s, "level")
        @test !contains(s, "module")
        @test !contains(s, "basename")
        @test !contains(s, "filepath")
        @test !contains(s, "line")
        @test !contains(s, "group")
        @test !contains(s, "module")
        @test !contains(s, "id")
        @test contains(s, "foo")
        @test contains(s, "Info")
    end
end

end # module
