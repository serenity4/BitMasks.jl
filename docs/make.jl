using Bitmasks
using Documenter

DocMeta.setdocmeta!(Bitmasks, :DocTestSetup, :(using Bitmasks); recursive=true)

makedocs(;
    modules=[Bitmasks],
    authors="Cédric BELMANT",
    repo="https://github.com/serenity4/Bitmasks.jl/blob/{commit}{path}#{line}",
    sitename="Bitmasks.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://serenity4.github.io/Bitmasks.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/Bitmasks.jl",
    devbranch="main",
)
