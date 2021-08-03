module MiscTest

using ReTest
using MiniLoggers
using Dates

@testset "flush" begin
    logger = MiniLogger(flush_threshold = 1000)
    @test logger.flush_threshold[] == 1000

    logger = MiniLogger(flush_threshold = Second(1))
    @test logger.flush_threshold[] == 1000
end

mutable struct MockIORecord
    buf::String
    flushed::Bool
end
MockIORecord(buf) = MockIORecord(buf, false)

mutable struct MockIO <: IO
    recs::Vector{MockIORecord}
end
MockIO() = MockIO(MockIORecord[])
function Base.flush(io::MockIO)
    foreach(io.recs) do rec
        rec.flushed = true
    end
end
Base.isopen(io::MockIO) = true
Base.write(io::MockIO, a::Vector{UInt8}) = push!(io.recs, MockIORecord(String(copy(a))))

@testset "delayed flush" begin
    io = MockIO()
    logger = MiniLogger(io = io, flush_threshold = 100, format = "{message}")
    sleep(0.2)
    with_logger(logger) do
        @info "Foo"
        @info "Bar"
    end
    @test length(io.recs) == 2
    @test io.recs[1].buf == "Foo\n"
    @test io.recs[2].buf == "Bar\n"
    @test io.recs[1].flushed
    @test !io.recs[2].flushed

    sleep(0.2)
    with_logger(logger) do
        @info "Baz"
    end
    @test length(io.recs) == 3
    @test all(x -> x.flushed, io.recs)
    @test io.recs[3].buf == "Baz\n"
end

end # module
