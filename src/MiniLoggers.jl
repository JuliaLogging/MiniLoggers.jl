module MiniLoggers

using Dates
using Markdown
import Logging: AbstractLogger, shouldlog, min_enabled_level, catch_exceptions, handle_message, LogLevel
using Logging: Warn, Info, Debug, Error, BelowMinLevel, AboveMaxLevel, global_logger, with_logger, default_logcolor

export MiniLogger, global_logger, with_logger

include("tokenizer.jl")
include("minilogger.jl")

end # module
