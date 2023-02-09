module MiniLoggers

using Dates
using Markdown
import Logging: AbstractLogger, shouldlog, min_enabled_level, catch_exceptions, handle_message, LogLevel
using Logging: Warn, Info, Debug, Error, BelowMinLevel, AboveMaxLevel, global_logger, with_logger, default_logcolor

export MiniLogger, JsonLogger, global_logger, with_logger

# Utils
include("common.jl")
include("tokenizer.jl")
include("modes.jl")

# Loggers
include("minilogger.jl")
include("jsonlogger.jl")

end # module
