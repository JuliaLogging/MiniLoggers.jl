using MiniLoggers
using Documenter

DocMeta.setdocmeta!(MiniLoggers, :DocTestSetup, :(using MiniLoggers); recursive=true)

makedocs(;
    modules=[MiniLoggers],
    authors="Andrey Oskin",
    repo="https://github.com/Arkoniak/MiniLogger.jl/blob/{commit}{path}#{line}",
    sitename="MiniLoggers.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Arkoniak.github.io/MiniLoggers.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Arkoniak/MiniLoggers.jl",
)
