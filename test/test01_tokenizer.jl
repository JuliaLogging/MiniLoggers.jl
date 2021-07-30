module TokenizerTest

using MiniLoggers
using MiniLoggers: Color, Token, colorparse, iscolored, tokenize
using ReTest

comptokens(t1, t2) = all(x == y for (x, y) in zip(t1, t2))

@testset "iscolored" begin
    @test iscolored(Color(:green, false))
    @test iscolored(Color(:green, true))
    @test iscolored(Color(-1, true))
    @test !iscolored(Color(-1, false))
end

@testset "colorparse correct" begin
    i, col = colorparse("xxx:red")
    @test i == 3
    @test col == Color(:red, false)

    i, col = colorparse("xxx:red:bold")
    @test i == 3
    @test col == Color(:red, true)

    i, col = colorparse("xxx:bold")
    @test i == 3
    @test col == Color(:normal, true)

    i, col = colorparse("xxx:5")
    @test i == 3
    @test col == Color(5, false)

    i, col = colorparse("xxx:5:bold")
    @test i == 3
    @test col == Color(5, true)
end

@testset "colorparse edge" begin
    i, col = colorparse(":red")
    @test i == 0
    @test col == Color(:red, false)

    i, col = colorparse(":red:bold")
    @test i == 0
    @test col == Color(:red, true)

    i, col = colorparse(":green:red:bold")
    @test i == 6
    @test col == Color(:red, true)

    i, col = colorparse(":3000:bold")
    @test i == 5
    @test col == Color(:normal, true)

    i, col = colorparse(":bold:3000")
    @test i == 10
    @test col == Color(-1, false)
end

@testset "basic token" begin
    @test Token("world:green:bold") == Token("world", Color(:green, true))
    @test Token(":green:bold") == Token("", Color(:green, true))
    @test Token("hello") == Token("hello", Color(-1, false))
end

@testset "basic tokenizer" begin
    res1 = tokenize("hello:red")
    res2 = [Token("hello", Color(:red, false))]
    @test comptokens(res1, res2)

    res1 = tokenize("{hello}")
    res2 = [Token("hello", Color(-1, false))]
    @test comptokens(res1, res2)

    res1 = tokenize("{hello} world:red")
    res2 = [Token("hello", Color(:red, false)), Token(" world", Color(:red, false))]
    @test comptokens(res1, res2)

    res1 = tokenize("and {hello:green:bold} world:red")
    res2 = [Token("and ", Color(:red, false)),
            Token("hello", Color(:green, true)),
            Token(" world", Color(:red, false))]
    @test comptokens(res1, res2)

    res1 = tokenize("{and {hello:green:bold} world:red}")
    res2 = [Token("and ", Color(:red, false)),
            Token("hello", Color(:green, true)),
            Token(" world", Color(:red, false))]
    @test comptokens(res1, res2)

    res1 = tokenize("and {hello:green:bold} world:")
    res2 = [Token("and ", Color(-1, false)),
            Token("hello", Color(:green, true)),
            Token(" world:", Color(-1, false))]
    @test comptokens(res1, res2)
end

end # module
