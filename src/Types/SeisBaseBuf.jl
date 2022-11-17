abstract type SeedBlk end

# [201] Murdock Event Detection Blockette (60 bytes)
mutable struct Blk201 <: SeedBlk
  sig::Array{Float32,1}
  flags::UInt8
  t::Array{Int32,1}
  det::String
  snr::Array{UInt8,1} # includes spots for lookback and pick algorithm
  Blk201() = new(zeros(Float32, 3),
                 0x00,
                 Array{Int32,1}(undef,7),
                 "None",
                 zeros(UInt8,8))
end

#  [500] Timing Blockette (200 bytes)
mutable struct Blk500 <: SeedBlk
  vco_correction::Float32
  t::Array{Int32,1}
  μsec::Int8
  reception_quality::Int8
  exception_count::UInt32
  exception_type::String
  clock_model::String
  clock_status::String
  Blk500() = new(0.0f0,
                 Array{Int32,1}(undef,7),
                 Int8(0),
                 Int8(0),
                 0x0000,
                 "",
                 "",
                 "")
end

# [2000] Variable Length Opaque Data Blockette
mutable struct Blk2000 <: SeedBlk
  n::UInt32
  NB::UInt16
  os::UInt16
  flag::UInt8
  hdr::Array{UInt8,1}
  data::Array{UInt8,1}
  Blk2000() = new(
                  0x00000000,
                  0x0000,
                  0x0000,
                  0x00,
                  Array{UInt8,1}(undef,0),
                  Array{UInt8,1}(undef,0)
                  )
end

# Calibration blockettes: [300], [310], [320], [390]
mutable struct BlkCalib <: SeedBlk
  t::Array{Int32,1}
  n::UInt8
  flags::UInt8
  dur1::UInt32
  dur2::UInt32
  amplitude::Float32
  period::Float32
  channel::Array{UInt8,1}
  ref::UInt32
  coupling::Array{UInt8,1}
  rolloff::Array{UInt8,1}
  noise::Array{UInt8,1}
  BlkCalib() = new( Array{Int32,1}(undef,7),
                    0x00,
                    0x00,
                    0x00000000,
                    0x00000000,
                    zero(Float32),
                    zero(Float32),
                    Array{UInt8,1}(undef, 3),
                    0x00000000,
                    Array{UInt8,1}(undef, 12),
                    Array{UInt8,1}(undef, 12),
                    Array{UInt8,1}(undef, 8)
                  )
end

mutable struct SeisBaseBuf
  fmt::UInt8    # 0x0a
  nx::UInt16    # 0x1000
  wo::UInt8     # 0x01
  tc::Int32     # Time correction
  swap::Bool
  calibs::Array{UInt16,1}

  # hdr:
  seq::Vector{UInt8}
  hdr::Vector{UInt8}
  hdr_old::Vector{UInt8}
  id::Array{UInt8,1}
  id_str::String
  #=  order of u16:
  1 year
  2 jdy
  3 record start time
  4 beginning of data
  5 first blockette
  6 position of next blockette (relative to record begin) =#

  # Values read from file/stream
  dt::Float64
  r1::Int16
  r2::Int16
  r1_old::Int16
  r2_old::Int16
  Δ::Int64
  xs::Bool
  k::Int
  n::UInt16

  # Data-related
  x::Array{Float32,1}         # Data buffer
  buf::Array{UInt8,1}         # Buffer for reading UInt8 data
  uint16_buf::Array{UInt16,1} # Used in SEG Y and SEED
  uint32_buf::Array{UInt32,1} # Unsigned 32-bit steim-encoded data
  int16_buf::Array{Int16,1}   # Buffer for int16s in headers
  int32_buf::Array{Int32,1}   # Buffer for int32s in headers
  int64_buf::Array{Int64,1}   # Buffer for int64s; used in rseis/wseis
  sac_fv::Array{Float32,1}
  sac_iv::Array{Int32,1}
  sac_cv::Array{UInt8,1}
  sac_dv::Array{Float64,1}
  flags::Array{UInt8,1}       # SEED flags (Stored as four UInt8s)

  # For parsing dates
  date_buf::Array{Int32,1}

  # For mini-SEED data header
  dh_arr::Array{UInt8, 1}
  dh_buf::Base.GenericIOBuffer{Array{UInt8,1}}

  # Blockette containers
  B201::Blk201
  B500::Blk500
  B2000::Blk2000
  Calib::BlkCalib

  function SeisBaseBuf()
    new(0xff,                               # fmt
        0x1000,                             # nx
        0x01,                               # wo
        zero(Int32),                        # tc
        false,                              # swap

        # SEED calibiration blockettes (all use the same parser)
        UInt16[0x012c, 0x0136, 0x0140, 0x0186],

        # SEED header
        Array{UInt8,1}(undef,8),            # seq::Vector{UInt8}
        Array{UInt8,1}(undef,12),           # hdr::Vector{UInt8}
        Array{UInt8,1}(undef,12),           # hdr_old::Vector{UInt8}
        Array{UInt8,1}(undef,15),           # id::Array{UInt8,1}
        "",                                 # id_str::String

        # computed
        0.0,                                # dt::Float64
        zero(Int16),                        # r1::Int16
        zero(Int16),                        # r2::Int16
        zero(Int16),                        # r1_old::Int16
        zero(Int16),                        # r2_old::Int16
        0,                                  # Δ::Int64
        false,                              # xs::Bool
        0,                                  # k::Int
        0x0000,                             # n::UInt16

        # data-related arrays
        Array{Float32,1}(undef, 65535),     # x::Array{Float32,1}
        Array{UInt8,1}(undef, 65535),       # buf::Array{UInt8,1}
        Array{UInt16,1}(undef, 6),          # uint16_buf::Array{UInt16,1}
        Array{UInt32,1}(undef, 16384),      # uint32_buf::Array{UInt32,1}
        Array{Int16,1}(undef, 62),          # int16_buf::Array{Int16,1}
        Array{Int32,1}(undef, 100),         # int32_buf::Array{Int32,1}
        Array{Int64,1}(undef, 8),           # int64_buf::Array{Int64,1}
        Array{Float32,1}(undef, 70),        # sac_fv::Array{Float32,1}
        Array{Int32,1}(undef, 40),          # sac_iv::Array{Int32,1}
        Array{UInt8,1}(undef, 192),         # sac_cv::Array{UInt8,1}
        Array{Float64,1}(undef,22),         # sac_dv::Array{Float64,1}
        Array{UInt8,1}(undef, 4),           # flags::Array{UInt8,1}

        # dedicated array for parsing dates
        Array{Int32,1}(undef, 7),           # date_buf::Array{Int32,1}

        # dedicated array for mini-SEED data header
        Array{UInt8,1}(undef, 48),          # dh_arr::Array{UInt8,1}
        IOBuffer(),                         # dh_buf::Base.GenericIOBuffer{Array{UInt8,1}}

        # blockette fields
        Blk201(),                           # Blk201:: Blk201
        Blk500(),                           # Blk500:: Blk500
        Blk2000(),                          # Blk2000:: Blk2000
        BlkCalib()                          # Calib:: BlkCalib
        )
  end
end

const BUF = SeisBaseBuf()
BUF.dh_buf = IOBuffer(BUF.dh_arr)
