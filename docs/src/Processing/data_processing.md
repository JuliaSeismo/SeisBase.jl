# Data Processing

Supported processing operations are described below.

In most cases, a "safe" version of each function can be invoked to create a new object with the processed output.

Any function that can logically operate on a single-channel object will do so. Any function that operates on a SeisData object can be applied to the :data field of a SeisEvent object.

## Basic Operations

These functions have no keywords that fundamentally change their behavior.

```@docs
demean!
detrend!
env!
nanfill!
resample!
unscale!
```

## Customizable Operations

### Convert Seismograms

Seismograms can be converted to or from displacement, velocity, or acceleration
using convert_seis:

```@docs
convert_seis!
```

### Fill Gaps

```@docs
ungap!
```

### Merge

```@docs
merge!
```

#### Merge Behavior

**Which channels merge?**
* Channels merge if they have identical values for ``:id``, ``:fs``, ``:loc``, ``:resp``, and ``:units``.
* An unset ``:loc``, ``:resp``, or ``:units`` field matches any set value in the corresponding field of another channel.


**What happens to merged fields?**
* The essential properties above are preserved.
* Other fields are combined.
* Merged channels with different `:name` values use the name of the channel with the latest data before the merge; other names are logged to `:notes`.


**What does ``merge!`` resolve?**

| Issue |  Resolution |
| ----- | ----------- |
| Empty channels | Delete |
| Duplicated channels | Delete duplicate channels |
| Duplicated windows in channel(s)  | Delete duplicate windows |
| Multiple channels, same properties [`1`] | Merge to a single channel |
| Channel with out-of-order time windows | Sort in chronological order |
| Overlapping windows, identical data, time-aligned | Windows merged |
| Overlapping windows, identical data, small time offset [`2`] | Time offset corrected, windows merged |
| Overlapping windows, non-identical data | Samples averaged, windows merged |

* [`1`]: "Properties" here are ``:id``, ``:fs``, ``:loc``, ``:resp``, and ``:units``.
* [`2`]: Data offset >4 sample intervals are treated as overlapping and non-identical.

**When SeisBase Won't Merge**
SeisBase does **not** combine data channels if **any** of the five fields above
are non-empty and different. For example, if a GphysData object S contains two
channels, each with id "XX.FOO..BHZ", but one has fs=100 Hz and the other fs=50 Hz,
**merge!** does nothing.

It's best to merge only unprocessed data. Data segments that were processed
independently (e.g. detrended) will be averaged pointwise when merged, which
can easily leave data in an unusuable state.

```@docs
mseis!
```

### Seismic Instrument Response

```@docs
translate_resp!
```

#### Precision and Memory Optimization
To optimize speed and memory use, instrument response translation maps data to
Complex{Float32} before translation; thus, with Float64 data, there can be
minor rounding errors.

Instrument responses are also memory-intensive. The minimum memory consumption
to translate the response of a gapless Float32 SeisChannel object is ~7x the
size of the object itself.

More precisely, for an object **S** (of Type <: GphysData or GphysChannel),
translation requires memory ~ 2 kB + the greater of (7x the size of the longest
Float32 segment, or 3.5x the size of the longest Float64 segment). Translation
uses four vectors -- three complex and one real -- that are updated and
dynamically resized as the algorithm loops over each segment:

* Old response container: Array{Complex{Float32,1}}(undef, Nx)
* New response container: Array{Complex{Float32,1}}(undef, Nx)
* Complex data container: Array{Complex{Float32,1}}(undef, Nx)
* Real frequencies for FFT: Array{Float32,1}(undef, Nx)

...where **Nx** is the number of samples in the longest segment in **S**.


#### Causality
Response translation adds no additional processing to guarantee causality. At
a minimum, most users will want to call ``detrend!`` and ``taper!`` before
translating instrument responses.


### Synchronize

```@docs
sync!
```


### Taper

```@docs
taper!
```

### Zero-Phase Filter

```@docs
filtfilt!
```

### Troubleshooting NaNs in Output
NaNs in the output of filtering operations (e.g., *filtfilt!*, *translate_resp!*) are nearly always the result of zeros in the denominator of the filter transfer function.

This is not a bug in SeisBase.

In particular, the increased speed of data processing at 32-bit precision comes with an increased risk of NaN output. The reason is that 32-bit machine epsilon (``eps(Float32)`` in Julia) is `~1.0e-7`; by comparison, 64-bit machine epsilon is `~1.0e-16`.

Please check for common signal processing issues before reporting NaNs to SeisBase maintainers. For example:

#### Filtering
* Is the pass band too narrow?
* Is the lower corner frequency too close to DC?
* Is the filter order (or number of poles) too high?

#### Instrument Responses
* Are the roll-off frequencies of the old and new responses too far apart?
* Is the water level appropriate for the data scaling?

#### Suggested References
1. Oppenheim, A.V., Buck, J.R. and Schafer, R.W., 2009. Discrete-time signal processing (3rd edition). Upper Saddle River, NJ, USA: Prentice Hall.
2. Orfanidis, S.J., 1995. Introduction to signal processing. Upper Saddle River, NJ, USA: Prentice Hall.
