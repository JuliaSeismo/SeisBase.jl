"""
    S = read_nodal(fmt, filestr [, keywords])

Read nodal data from file `filestr` into new NodalData object `S`.

## Keywords
|KW     | Type      | Default   | Used By   | Meaning                         |
|:---   |:---       |:---       |:---       |:---                             |
| chans | ChanSpec  | Int64[]   | all       | channel numbers to read in      |
| nn    | String    | "N0"      | all       | network name in `:id`           |
| s     | TimeSpec  |           | silixa    | start time [1]                  |
| t     | TimeSpec  |           | silixa    | end time                        |
| v     | Integer   | 0         | silixa    | verbosity                       |

1. Special behavior: Real values supplied to `s=` and `t=` are treated as seconds *from file begin*; 
    most SeisBase functions treat Real as seconds relative to current time.

## Non-Standard Behavior
Real values supplied to keywords ``s=`` and ``t=`` are treated as seconds *relative to file begin time*. 
Most SeisBase functions that accept TimeSpec arguments treat Real values as seconds relative to ``now()``.

## Supported File Formats

| File Format | String    | Notes                                               |
| :---        | :---      | :---                                                |
| Silixa TDMS | silixa    | Limited support; see below                          |
| SEG Y       | segy      | Field values are different from *read_data* output  | 

## Silixa TDMS Support Status

* Currently only reads file header and samples from first block
* Not yet supported (test files needed):
    * first block additional samples
    * second block
    * second block additional samples
* Awaiting manufacturer clarification:
    * parameters in *:info*
    * position along cable; currently loc.(x,y,z) = 0.0 for all channels
    * frequency response; currently ``:resp`` is an all-pass placeholder

## Nodal SEG Y Support Status
See [SEG Y Support](@ref segy).


See also: `TimeSpec`, `parsetimewin`, `read_data`
"""
function read_nodal(fmt::String, fstr::String;
  chans   ::ChanSpec  = Int64[]                   , # channels to proess
  memmap  ::Bool      = false                     , # use mmap? (DANGEROUS)
  nn      ::String    = "N0"                      , # network name
  s       ::TimeSpec  = "0001-01-01T00:00:00"     , # Start
  t       ::TimeSpec  = "9999-12-31T12:59:59"     , # End or Length (s)
  v       ::Integer   = KW.v                      , # verbosity
  )

  if fmt == "silixa"
    S = read_silixa_tdms(fstr, nn, s, t, chans, memmap, v)
  elseif fmt == "segy"
    S = read_nodal_segy(fstr, nn, s, t, chans, memmap)
  else
    error("Unrecognized format String!")
  end
  return S
end
