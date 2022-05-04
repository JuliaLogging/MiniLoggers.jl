module LoggerFormatTest

using MiniLoggers
using ReTest

conts(s, sub) = match(Regex(sub), s) !== nothing

@testset "basic format" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, minlevel = MiniLoggers.Debug,
                        format = "{timestamp}:{level}:{module}:{basename}:{filepath}:{line}:{group}:{module}:{id}:{message}")
    with_logger(logger) do
        @info "foo"
        s = String(take!(io))
        @test !conts(s, "timestamp")
        @test !conts(s, "level")
        @test !conts(s, "module")
        @test !conts(s, "basename")
        @test !conts(s, "filepath")
        @test !conts(s, "line")
        @test !conts(s, "group")
        @test !conts(s, "module")
        @test !conts(s, "id")
        @test conts(s, "foo")
        @test conts(s, "Info")
    end
end

@testset "contracting kwarg values" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, format = "{message}")
    with_logger(logger) do
        @info "hello" x = 4 y = 2
        s = String(take!(io))
        @test s == "hello x = 4, y = 2\n"

        @info "hello"
        s = String(take!(io))
        @test s == "hello\n"

        # Due to the way message is generated, it is impossible to make it more natural
        @info x = 4 y = 2
        s = String(take!(io))
        @test s == "4 y = 2\n"

        @info "hello" x = 4 " and " y = 2
        s = String(take!(io))
        @test s == "hello x = 4 and y = 2\n"
    end
end

@testset "squashing" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, format = "{message}")
    with_logger(logger) do
        @info "foo\nbar"

        s = String(take!(io))
        @test s == "foo\tbar\n"
    end

    logger = MiniLogger(io = io, format = "{message}", message_mode = :notransformations)
    with_logger(logger) do
        @info "foo\nbar"

        s = String(take!(io))
        @test s == "foo\nbar\n"
    end
end

@testset "squashing values" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, format = "{message}", squash_delimiter = "XXX")
    val = "foo\nbar"
    with_logger(logger) do
        @info "" x = val
        s = String(take!(io))

        @test s == "x = fooXXXbar\n"
    end

    val = "bar\n\rfoo"
    with_logger(logger) do
        @info "" x = val
        s = String(take!(io))

        @test s == "x = barXXXfoo\n"
    end
end

@testset "markdown support" begin
    io = IOBuffer()
    ioc = IOContext(io, :color => true)
    logger = MiniLogger(io = ioc, format = "{message}", message_mode = :markdown)
    with_logger(logger) do
        @info "**foo**"

        s = String(take!(io))
        @test s == "  \e[1mfoo\e[22m\n"
    end
end

@testset "badcaret" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, format = "{message}")
    with_logger(logger) do
        @info "foo\r\nbar"
        
        s = String(take!(io))
        @test s == "foo\tbar\n"
    end
end

@testset "kwargs" begin
    io = IOBuffer()
    logger = MiniLogger(io = io, format = "{message}")
    x = 1
    y = "asd"

    with_logger(logger) do
        @info "values:" x y
    
        s = String(take!(io))
        @test s == "values: x = 1, y = asd\n"
    end
end

@testset "error catching" begin
    io = IOBuffer()
    logger = MiniLogger(ioerr = io, format = "{message}")
    
    with_logger(logger) do
        try
            error("ERROR")
        catch err
            @error (err, catch_backtrace())
        end

        s = String(take!(io))
        @test conts(s, "^ERROR\n *Stacktrace")

        try
            error("ERROR")
        catch err
            @error "foo" exception = (err, catch_backtrace())
        end

        s = String(take!(io))
        @test conts(s, "^foo exception = ERROR\n *Stacktrace")

        try
            error("ERROR")
        catch err
            @error err
        end
        s = String(take!(io))
        @test s == "ERROR\n"

        try
            error("ERROR")
        catch err
            @error catch_backtrace()
        end
        s = String(take!(io))
        @test conts(s, "^\n *Stacktrace")
    end
end

@testset "logstring colors" begin
    io = IOBuffer()
    ioc = IOContext(io, :color => true)
    logger = MiniLogger(io = ioc, ioerr = ioc, format = "{foo:cyan} {bar:bold} {level:func}:{message}", minlevel = MiniLoggers.Debug)

    with_logger(logger) do
        @debug "foo"
        s = String(take!(io))

        @test s == "\e[36mfoo\e[39m \e[0m\e[1mbar\e[22m \e[34mDebug\e[39m:foo\n"

        @info "foo"
        s = String(take!(io))

        @test s == "\e[36mfoo\e[39m \e[0m\e[1mbar\e[22m \e[36mInfo\e[39m:foo\n"

        @warn "foo"
        s = String(take!(io))

        @test s == "\e[36mfoo\e[39m \e[0m\e[1mbar\e[22m \e[33mWarn\e[39m:foo\n"

        @error "foo"
        s = String(take!(io))

        @test s == "\e[36mfoo\e[39m \e[0m\e[1mbar\e[22m \e[91mError\e[39m:foo\n"
    end
end

end # module
