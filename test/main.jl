module MiniLoggersTest

using ReTest

for file in sort([file for file in readdir(@__DIR__) if
                  occursin(r"^test.*\.jl$", file)])
    include(file)
end

end # module
