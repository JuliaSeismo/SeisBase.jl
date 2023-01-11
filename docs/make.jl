push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using SeisBase, Documenter

pages = Any[
    "Home" => "index.md",
    "Intro" => [
        "Introduction" => "Intro/intro.md",
        "First Steps" => "Intro/first_steps.md",
        "Working with data" => "Intro/working_with_data.md",
        "Getting Help" => "Intro/getting_help.md",
    ],
    "Reading files" => [
        "Time-Series Files" => "ReadingFiles/timeseries.md",
        "Metadata Files" => "ReadingFiles/metadata.md",
        "HDF5 Files" => "ReadingFiles/hdf5.md",
        "XML Meta-Data" => "ReadingFiles/xml.md",
    ],
    "Downloading" => [
        "Web Services" => "Downloading/web_services.md",
        "SeedLink" => "Downloading/seedlink.md",
    ],
    "Writing files" => [
        "Write Support" => "WritingFiles/writing.md",
    ],
    "Processing" => [
        "Data Processing" => "Processing/data_processing.md",
    ],
    "Submodules" => [
        "Submodules" => "Submodules/submodules.md",
        "Nodal" => "Submodules/nodal.md",
        "Quake" => "Submodules/quake.md",
        "SeisHDF" => "Submodules/seishdf.md",
    ],
    "Appendices" => [
        "Appendices" => "Appendices/appendix.md",
    ],
]

makedocs(
    sitename="SeisBase.jl",
    modules = [SeisBase],
    pages = pages,
)

deploydocs(
    repo = "github.com/JuliaSeismo/SeisBase.jl.git",
    devbranch = "main",
    push_preview = true,
    forcepush = true,
)
