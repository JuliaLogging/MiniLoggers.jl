struct MiniLogger{IOT1 <: IO, IOT2 <: IO, DFT <: DateFormat} <: AbstractLogger
    io::IOT1
    ioerr::IOT2
    errlevel::LogLevel
    minlevel::LogLevel
    message_limits::Dict{Any,Int}
    flush::Bool
    format::Vector{Token}
    dtformat::DFT
end

getio(io) = io
getio(io::AbstractString) = open(io)

function MiniLogger(; io = stdout, ioerr = stderr, errlevel = Error, minlevel = Info, message_limits = Dict{Any, Int}(), flush = true, format = "{[{datetime}]:func} {message}", dtformat = dateformat"yyyy-mm-dd HH:MM:SS")
    tio = getio(io)
    tioerr = io == ioerr ? tio : getio(ioerr)
    MiniLogger(tio, tioerr, errlevel, minlevel, message_limits, flush, tokenize(format), dtformat)
end

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

function colorfunc(level::LogLevel, _module, group, id, filepath, line, element)
    level < Info  ? Color(Base.debug_color()) :
    level < Warn  ? Color(Base.info_color())  :
    level < Error ? Color(Base.warn_color())  :
                    Color(Base.error_color())
end

function extractcolor(token::Token, level, _module, group, id, filepath, line)
    if token.c.c == :func
        color = colorfunc(level, _module, group, id, filepath, line, token.val)
        return Color(color.c, color.isbold || token.c.isbold)
    else
        return token.c
    end
end

function printwcolor(iob, val, color)
    if color.c == -1
        if color.isbold
            printstyled(iob, val; bold = color.isbold)
        else
            print(iob, val)
        end
    else
        printstyled(iob, val; color = color.c, bold = color.isbold)
    end
end

function handle_message(logger::MiniLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
    if maxlog !== nothing && maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end

    io = if level < logger.errlevel
            isopen(logger.io) ? logger.io : stdout
        else
            isopen(logger.ioerr) ? logger.ioerr : stderr
        end

    buf = IOBuffer()
    iob = IOContext(buf, io)

    for token in logger.format
        c = extractcolor(token, level, _module, group, id, filepath, line)
        val = token.val
        if val == "datetime"
            printwcolor(iob, tsnow(logger.dtformat), c)
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
            printwcolor(iob, levelstr, c)
        elseif val == "basename"
            printwcolor(iob, basename(filepath), c)
        elseif val == "filepath"
            printwcolor(iob, filepath, c)
        elseif val == "line"
            printwcolor(iob, line, c)
        elseif val == "group"
            printwcolor(iob, group, c)
        elseif val == "module"
            printwcolor(iob, _module, c)
        elseif val == "id"
            printwcolor(iob, id, c)
        else
            printwcolor(iob, val, c)
        end
    end
    print(iob, "\n")
    write(io, take!(buf))
    if logger.flush
        flush(io)
    end
    nothing
end

