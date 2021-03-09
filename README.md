# MiniLogger

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Arkoniak.github.io/MiniLoggers.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Arkoniak.github.io/MiniLoggers.jl/dev)
[![Build Status](https://github.com/Arkoniak/MiniLoggers.jl/workflows/CI/badge.svg)](https://github.com/Arkoniak/MiniLoggers.jl/actions)
[![Coverage](https://codecov.io/gh/Arkoniak/MiniLoggers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Arkoniak/MiniLoggers.jl)

# Installation

Currently `MiniLoggers.jl` are not part of General registry, so it should be installed with

```julia
julia> Pkg.dev("https://github.com/Arkoniak/MiniLoggers.jl.git")
```

# Usage

`MiniLoggers.jl` are build around the idea of extremely simple and visually compact logger, with output format defined by string in the same manner as in [python logging module](https://docs.python.org/3/howto/logging.html#changing-the-format-of-displayed-messages). It uses `stdout` by default and intended to be use instead of the usual `print` commands.
