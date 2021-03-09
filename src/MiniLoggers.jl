module MiniLoggers

using Dates
import Logging: AbstractLogger, shouldlog, min_enabled_level, catch_exceptions, handle_message, LogLevel
import Logging: Warn, Info

export MiniLogger

struct MiniLogger <: AbstractLogger
    stream::IO
    minlevel::LogLevel
    message_limits::Dict{Any,Int}
end

MiniLogger(stream::IO, level) = MiniLogger(stream, level, Dict())
MiniLogger(; stream::IO = stdout, level=Info) = MiniLogger(stream, level, Dict())
MiniLogger(stream::IO; level=Info) = MiniLogger(stream, level, Dict())

shouldlog(logger::MiniLogger, level, _module, group, id) =
    get(logger.message_limits, id, 1) > 0

min_enabled_level(logger::MiniLogger) = logger.minlevel

catch_exceptions(logger::MiniLogger) = true

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
    print(iob, "[", Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS"), "] - ", levelstr, " - ")

    msglines = split(chomp(string(message)), '\n')
    print(iob, msglines[1])
    for i in 2:length(msglines)
        print(iob, " ", msglines[i])
    end

    # println(iob, "┌ ", levelstr, ": ", msglines[1])
    # for i in 2:length(msglines)
    #     println(iob, "│ ", msglines[i])
    # end
    # if !isempty(kwargs)
    #     print(iob, " {")
    # end
    iscomma = false
    for (key, val) in kwargs
        # print(iob, val)
        if string(key) == val
            print(iob, key)
            iscomma = false
        else
            iscomma && print(iob, ", ")
            print(iob, key, " = ", val)
            iscomma = true
        end
    end
    # if !isempty(kwargs)
    #     print(iob, "}")
    # end
    print(iob, "\n")
    # println(iob, "└ @ ", something(_module, "nothing"), " ",
    #         something(filepath, "nothing"), ":", something(line, "nothing"))
    write(logger.stream, take!(buf))
    nothing
end

end # module
