module MiniLoggers

using Dates
import Logging: AbstractLogger, shouldlog, min_enabled_level, catch_exceptions, handle_message, LogLevel
using Logging: Warn, Info, Debug, Error, BelowMinLevel, AboveMaxLevel, global_logger, with_logger

export MiniLogger, global_logger, with_logger

struct MiniLogger <: AbstractLogger
    stream::IO
    minlevel::LogLevel
    message_limits::Dict{Any,Int}
    flush::Bool
end

MiniLogger(stream::IO, level) = MiniLogger(stream, level, Dict(), true)
MiniLogger(; stream::IO = stdout, level = Info, flush = true) = MiniLogger(stream, level, Dict(), flush)
MiniLogger(stream::IO; level = Info, flush = true) = MiniLogger(stream, level, Dict(), flush)

shouldlog(logger::MiniLogger, level, _module, group, id) =
    get(logger.message_limits, id, 1) > 0

min_enabled_level(logger::MiniLogger) = logger.minlevel

catch_exceptions(logger::MiniLogger) = true

# Formatting of values in key value pairs
showvalue(io, msg) = show(io, "text/plain", msg)
function showvalue(io, e::Tuple{Exception,Any})
    ex, bt = e
    Base.showerror(io, ex, bt; backtrace = bt!==nothing)
end
showvalue(io, ex::Exception) = Base.showerror(io, ex)
showvalue(io, ex::AbstractVector{Union{Ptr{Nothing}, Base.InterpreterIP}}) = Base.show_backtrace(io, ex)

function showmessage(io, msg)
    msglines = split(chomp(string(msg)), '\n')
    print(io, msglines[1])
    for i in 2:length(msglines)
        print(io, " ", msglines[i])
    end
end
showmessage(io, e::Tuple{Exception,Any}) = showvalue(io, e)
showmessage(io, ex::Exception) = showvalue(io, e)
showmessage(io, ex::AbstractVector{Union{Ptr{Nothing}, Base.InterpreterIP}}) = Base.show_backtrace(io, ex)

function handle_message(logger::MiniLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
    if maxlog !== nothing && maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end

    buf = IOBuffer()
    iob = IOContext(buf, logger.stream)

    levelstr = level == Warn ? "Warning" : string(level)
    print(iob, "[", Dates.format(Dates.now(), Dates.dateformat"yyyy-mm-dd HH:MM:SS"), "] ", _module, ":", basename(filepath), ":", line, " ", levelstr, ": ")

    showmessage(iob, message)

    iscomma = false
    for (key, val) in kwargs
        # print(iob, val)
        if string(key) == val
            print(iob, key)
            iscomma = false
        else
            iscomma && print(iob, ", ")
            print(iob, key, " = ")
            showvalue(iob, val)
            iscomma = true
        end
    end
    print(iob, "\n")
    # println(iob, "└ @ ", something(_module, "nothing"), " ",
    #         something(filepath, "nothing"), ":", something(line, "nothing"))
    write(logger.stream, take!(buf))
    if logger.flush
        flush(logger.stream)
    end
    nothing
end

end # module
