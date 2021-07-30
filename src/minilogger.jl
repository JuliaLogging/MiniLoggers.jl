struct MiniLogger{IOT1 <: IO, IOT2 <: IO} <: AbstractLogger
    io::IOT1
    ioerr::IOT2
    errlevel::LogLevel
    minlevel::LogLevel
    message_limits::Dict{Any,Int}
    flush::Bool
    format::Vector{Token}
end

MiniLogger(; io = stdout, ioerr = stderr, errlevel = Error, minlevel = Info, message_limits = Dict{Any, Int}(), flush = true, format = "{message}") = MiniLogger(io, ioerr, errlevel, minlevel, message_limits, flush, tokenize(format))

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

tsnow(dtf) = Dates.format(Dates.now(), dtf)

function handle_message(logger::MiniLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
    if maxlog !== nothing && maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end

    io = level < logger.errlevel ? logger.io : logger.ioerr

    buf = IOBuffer()
    iob = IOContext(buf, io)

    for token in logger.format
        val = token.val
        if val == "datetime"
            print(iob, tsnow(Dates.dateformat"yyyy-mm-dd HH:MM:SS"))
        elseif val == "date"
            print(iob, tsnow(Dates.dateformat"yyyy-mm-dd"))
        elseif val == "message"
            showmessage(iob, message)

            iscomma = false
            for (key, val) in kwargs
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
        elseif val == "level"
            levelstr = string(level)
            print(iob, levelstr)
        elseif val == "basename"
            print(iob, basename(filepath))
        elseif val == "filepath"
            print(iob, filepath)
        elseif val == "line"
            print(iob, line)
        elseif val == "group"
            print(iob, group)
        elseif val == "module"
            print(iob, _module)
        elseif val == "id"
            print(iob, id)
        else
            print(iob, val)
        end
    end
    print(iob, "\n")
    write(io, take!(buf))
    if logger.flush
        flush(io)
    end
    nothing
end

