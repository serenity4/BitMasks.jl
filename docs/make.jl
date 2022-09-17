using BitMasks
using Documenter

DocMeta.setdocmeta!(BitMasks, :DocTestSetup, :(using BitMasks); recursive=true)

makedocs(;
    modules=[BitMasks],
    authors="Cédric BELMANT",
    repo="https://github.com/serenity4/BitMasks.jl/blob/{commit}{path}#{line}",
    sitename="BitMasks.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://serenity4.github.io/BitMasks.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/BitMasks.jl",
    devbranch="main",
)
