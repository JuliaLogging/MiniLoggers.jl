module LoggerFormatTest

using MiniLoggers
using ReTest

@testset "basic format" begin
    io = IOBuffer()
    logger = MiniLogger(io, level = MiniLoggers.Debug,
                        format = "{level} - {module}:{line}: {message}")
end

end # module
