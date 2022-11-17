push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using SeisBase, Documenter

pages = Any[
    "Home" => "index.md",
    "Intro" => [
        "Introduction" => "intro.md",
        "First Steps" => "first_steps.md",
        "Working with data" => "working_with_data.md",
        "Getting Help" => "getting_help.md",
    ],
    "Reading files" => [
        "Time-Series Files" => "time_series_files.md",
        "Metadata Files" => "metadata_files.md",
        "HDF5 Files" => "hdf5_files.md",
        "XML Meta-Data" => "xml_metadata.md",
    ],
    "Downloading" => [
        "Web Services" => "web_services.md",
        "SeedLink" => "seedlink.md",
    ],
    "Writing files" => [
        "Write Support" => "write_support.md",
    ],
    "Processing" => [
        "Data Processing" => "data_processing.md",
    ],
    "Submodules" => [
        "Submodules" => "submodules.md",
        "Nodal" => "nodal.md",
        "Quake" => "quake.md",
        "SeisHDF" => "seishdf.md",
    ],
    "Appendices" => [
        "Appendices" => "appendices.md",
    ],
]

makedocs(
    sitename="SeisBase.jl",
    modules = [SeisBase],
    pages = pages,
)

deploydocs(
    repo = "github.com/SeismoJulia/SeisBase.jl.git",
    devbranch = "main",
    push_preview = true,
    forcepush = true,
)
