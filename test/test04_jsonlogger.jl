module JsonLoggerTest

using MiniLoggers
using MiniLoggers: Token, tokenize, JsonLoggerTokenizer
using ReTest

comptokens(t1, t2) = all(x.val == y for (x, y) in zip(t1, t2))

@testset "JsonLogger tokenize function" begin
    @testset "simple word" begin
        res1 = tokenize(JsonLoggerTokenizer(), "x")
        @test comptokens(res1, ["{", "\"x\"", ":", "x", "}"])
    end

    @testset "comma separated" begin
        res1 = tokenize(JsonLoggerTokenizer(), "x,y")
        @show res1
        @test comptokens(res1, ["{", "\"x\"", ":", "x", ",", "\"y\"", ":", "y", "}"])
    end

    @testset "colon separated" begin
        res1 = tokenize(JsonLoggerTokenizer(), "x:y")
        @test comptokens(res1, ["{", "\"x\"", ":", "y", "}"])
    end

    @testset "nested values" begin
        res1 = tokenize(JsonLoggerTokenizer(), "x:{y}")
        @test comptokens(res1, ["{", "\"x\"", ":", "{", "\"y\"", ":", "y", "}", "}"])
    end
end

@testset "JsonLogger printing" begin
    x = 1
    y = "asd"
    x1 = 2
    z = "z"

    d = Dict("asd" => 1, 'a' => 0.34)

    buf = IOBuffer()
    iob = IOContext(buf, stdout)
    JsonLogger(io = iob, format = tokenize(JsonLoggerTokenizer(), "severity:level,source:{line:level,level},message"), minlevel = MiniLoggers.Debug) |> global_logger
    begin
        @debug "V:" x y
    end

    s = String(take!(buf))
    @test s == "{\"severity\":\"Debug\",\"source\":{\"line\":\"Debug\",\"level\":\"Debug\"},\"message\":\"V: x = 1, y = asd\"}\n"
end

end # module
