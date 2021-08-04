include(joinpath(@__DIR__, "main.jl"))

# You can run `Pkg.test("MiniLoggers", test_args = ["foo", "bar"])` or just 
# `Pkg.test(test_args = ["foo", "bar"])` to select only specific tests. If no `test_args` 
# is given or you are running usual `> ] test` command, then all tests are executed.
if isempty(ARGS)
    MiniLoggersTest.runtests()
else
    MiniLoggersTest.runtests(ARGS)
end
