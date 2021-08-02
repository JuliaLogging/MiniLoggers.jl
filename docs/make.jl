using MiniLoggers
using Documenter

DocMeta.setdocmeta!(MiniLoggers, :DocTestSetup, :(using MiniLoggers); recursive=true)

makedocs(;
    modules=[MiniLoggers],
    authors="Andrey Oskin",
    repo="https://github.com/JuliaLogging/MiniLoggers.jl/blob/{commit}{path}#{line}",
    sitename="MiniLoggers.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaLogging.github.io/MiniLoggers.jl",
        siteurl="https://github.com/JuliaLogging/MiniLoggers.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaLogging/MiniLoggers.jl",
)
