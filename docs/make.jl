using MiniLogger
using Documenter

DocMeta.setdocmeta!(MiniLogger, :DocTestSetup, :(using MiniLogger); recursive=true)

makedocs(;
    modules=[MiniLogger],
    authors="Andrey Oskin",
    repo="https://github.com/Arkoniak/MiniLogger.jl/blob/{commit}{path}#{line}",
    sitename="MiniLogger.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Arkoniak.github.io/MiniLogger.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Arkoniak/MiniLogger.jl",
)
