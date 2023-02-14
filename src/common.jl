abstract type AbstractMiniLogger <: AbstractLogger end

shouldlog(logger::AbstractMiniLogger, level, _module, group, id) = lock(logger.lock) do
    get(logger.message_limits, id, 1) > 0
end

min_enabled_level(logger::AbstractMiniLogger) = logger.minlevel

catch_exceptions(logger::AbstractMiniLogger) = true

function Base.close(logger::AbstractMiniLogger)
    if logger.io != stdout && logger.io != stderr && isopen(logger.io)
        close(logger.io)
    end

    if logger.ioerr != stdout && logger.ioerr != stderr && isopen(logger.ioerr)
        close(logger.ioerr)
    end
end

getio(io, append) = io
getio(io::AbstractString, append) = open(io, append ? "a" : "w")

getflushthreshold(x::Integer) = x
getflushthreshold(x::TimePeriod) = Dates.value(Millisecond(x))

tsnow(dtf) = Dates.format(Dates.now(), dtf)
