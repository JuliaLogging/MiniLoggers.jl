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
    @testset "Simple logging" begin
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

    @testset "quotes escape" begin
        s = "\""
        buf = IOBuffer()
        iob = IOContext(buf, stdout)
        JsonLogger(io = iob, format = tokenize(JsonLoggerTokenizer(), "message"), minlevel = MiniLoggers.Debug) |> global_logger
        begin
            @debug "V:" s
        end

        s1 = String(take!(buf))
        @test s1 == "{\"message\":\"V: s = \\\"\"}\n"
    end
end

end # module
