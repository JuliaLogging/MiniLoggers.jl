struct MiniLogger{AM <: AbstractMode, IOT1 <: IO, IOT2 <: IO, DFT <: DateFormat, F} <: AbstractMiniLogger
    io::IOT1
    ioerr::IOT2
    errlevel::LogLevel
    minlevel::LogLevel
    message_limits::Dict{Any,Int}
    flush::Bool
    format::Vector{Token}
    dtformat::DFT
    mode::AM
    squash_delimiter::String
    flush_threshold::Int
    lastflush::Base.RefValue{Int64}
    lock::ReentrantLock # thread-safety of message_limits Dict
    levelname::F
end

getmode(mode) = mode
getmode(mode::AbstractString) = getmode(Symbol(mode))
function getmode(mode::Symbol)
    if mode == :notransformations
        return NoTransformations()
    elseif mode == :squash
        return Squash()
    elseif mode == :fullsquash
        return FullSquash()
    elseif mode == :markdown
        return MDown()
    end
end

"""
    MiniLogger(; <keyword arguments>)

MiniLogger constructor creates custom logger which can be used with usual `@info`, `@debug` commands.

Supported keyword arguments include:

* `io` (default `stdout`): IO stream which is used to output log messages below `errlevel` level. Can be either `IO` or `String`, in the latter case it is treated as a name of the output file.
* `ioerr` (default `stderr`): IO stream which is used to output log messages above `errlevel` level. Can be either `IO` or `String`, in the latter case it is treated as a name of the output file.
* `errlevel` (default `Error`): determines which output IO to use for log messages. If you want for all messages to go to `io`, set this parameter to `MiniLoggers.AboveMaxLevel`. If you want for all messages to go to `ioerr`, set this parameter to `MiniLoggers.BelowMinLevel`.
* `minlevel` (default: `Info`): messages below this level are ignored. For example with default setting `@debug "foo"` is ignored.
* `append` (default: `false`): defines whether to append to output stream or to truncate file initially. Used only if `io` or `ioerr` is a file path.
* `message_mode` (default: `:squash`): choose how message is transformed before being printed out. Following modes are supported:
    * `:notransformations`: message printed out as is, without any extra transformations
    * `:squash`: message is squashed to a single line, i.e. all `\\n` are changed to `squash_delimiter` and `\\r` are removed.
    * `:fullsquash`: all messages including error stacktraces are squashed to a single line, i.e. all `\\n` are changed to `squash_delimiter` and `\\r` are removed
    * `:markdown`: message is treated as if it is written in markdown
* `squash_delimiter`: (default: "\\t"): defines which delimiter to use in squash mode.
* `flush` (default: `true`): whether to `flush` IO stream for each log message. Flush behaviour also affected by `flush_threshold` argument.
* `flush_threshold::Union{Integer, TimePeriod}` (default: 0): if this argument is nonzero and `flush` is `true`, then `io` is flushed only once per `flush_threshold` milliseconds. I.e. if time between two consecutive log messages is less then `flush_threshold`, then second message is not flushed and will have to wait for the next log event.
* `dtformat` (default: "yyyy-mm-dd HH:MM:SS"): if `datetime` parameter is used in `format` argument, this dateformat is applied for output timestamps.
* `levelname` (default `string`): allows to redefine output of log level names. Should be function of the form `levelname(level::LogLevel)::String`
* `format` (default: "[{timestamp:func}] {level:func}: {message}"): format for output log message. It accepts following keywords, which should be provided in curly brackets:
    * `timestamp`: timestamp of the log message
    * `level`: name of log level (Debug, Info, etc)
    * `filepath`: filepath of the file, which produced log message
    * `basename`: basename of the filepath of the file, which produced log message
    * `line`: line number of the log command in the file, which produced log message
    * `group`: log group
    * `module`: name of the module, which contains log command
    * `id`: log message id
    * `message`: message itself

Each keyword accepts color information, which should be added after colon inside curly brackets. Colors can be either from `Base.text_colors` or special keyword `func`, in which case is used automated coloring. Additionaly, `bold` modifier is accepted by the `format` argument. For example: `{line:red}`, `{module:cyan:bold}`, `{group:func}` are all valid parts of the format command.

Colour information is applied recursively without override, so `{{line} {module:cyan} {group}:red}` is equivalent to `{line:red} {module:cyan} {group:red}`.

If part of the format is not a recognised keyword, then it is just used as is, for example `{foo:red}` means that output log message contain word "foo" printed in red.
"""
function MiniLogger(; io = stdout, ioerr = stderr, errlevel = Error, minlevel = Info, append = false, message_limits = Dict{Any, Int}(), flush = true, format = "[{timestamp:func}] {level:func}: {message}", dtformat = dateformat"yyyy-mm-dd HH:MM:SS", flush_threshold = 0, message_mode = Squash(), squash_delimiter = "\t", levelname = string)
    tio = getio(io, append)
    tioerr = io == ioerr ? tio : getio(ioerr, append)
    lastflush = Dates.value(Dates.now())
    MiniLogger(tio,
               tioerr,
               errlevel,
               minlevel,
               message_limits,
               flush,
               tokenize(format),
               dtformat,
               getmode(message_mode),
               squash_delimiter,
               getflushthreshold(flush_threshold),
               Ref(lastflush),
               ReentrantLock(),
               levelname)
end


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
        remaining = lock(logger.lock) do
            logger.message_limits[id] = max(get(logger.message_limits, id, maxlog), 0) - 1
        end
        remaining ≥ 0 || return
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
        if val == "timestamp"
            printwcolor(iob, tsnow(logger.dtformat), c)
        elseif val == "message"
            showmessage(iob, message, logger, logger.mode)
            if length(kwargs) > 0 && !isempty(message)
                print(iob, " ")
            end

            iscomma = false
            for (k, v) in kwargs
                if string(k) == v
                    print(iob, k)
                    iscomma = false
                else
                    iscomma && print(iob, ", ")
                    print(iob, k, " = ")
                    showvalue(iob, v, logger, logger.mode)
                    iscomma = true
                end
            end
        elseif val == "level"
            levelstr = logger.levelname(level)
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
    write(io, postprocess(logger.mode, logger.squash_delimiter, buf))
    if logger.flush
        if logger.flush_threshold <= 0
            flush(io)
        else
            t = Dates.value(Dates.now())
            if t - logger.lastflush[] >= logger.flush_threshold
                logger.lastflush[] = t
                flush(io)
            end
        end
    end
    nothing
end
