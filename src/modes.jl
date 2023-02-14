abstract type AbstractMode end
struct NoTransformations <: AbstractMode end
struct Squash <: AbstractMode end
struct FullSquash <: AbstractMode end
struct MDown <: AbstractMode end
struct JsonSquash <: AbstractMode end

# Formatting of values in key value pairs
squash(msg, logger, mode) = string(msg)
function squash(msg, logger, mode::Union{Squash, FullSquash})
    smsg = string(msg)
    smsg = replace(smsg, "\r" => "")
    smsg = replace(smsg, "\n" => logger.squash_delimiter)
end

function squash(msg, logger, mode::JsonSquash)
    smsg = string(msg)
    # Far from perfect, but should cover most cases. If we run into any issues, we can add more complicated processing
    smsg = replace(smsg, "\"" => "\\\"")
    smsg = replace(smsg, "\r" => "")
    smsg = replace(smsg, "\n" => logger.squash_delimiter)
end

showvalue(io, msg, logger, mode) = print(io, squash(msg, logger, mode))

function showvalue(io, e::Tuple{Exception,Any}, logger, mode)
    ex, bt = e
    Base.showerror(io, ex, bt; backtrace = bt!==nothing)
end
showvalue(io, ex::Exception, logger, mode) = Base.showerror(io, ex)
showvalue(io, ex::AbstractVector{Union{Ptr{Nothing}, Base.InterpreterIP}}, logger, mode) = Base.show_backtrace(io, ex)

# Here we are fighting with multiple dispatch.
# If message is `Exception` or `Tuple{Exception, Any}` or anything else
# then we want to ignore third argument.
# But if it is any other sort of message we want to dispatch result
# on the type of message transformation
_showmessage(io, msg, logger, mode) = print(io, squash(msg, logger, mode))
_showmessage(io, msg, logger, ::MDown) = show(io, MIME"text/plain"(), Markdown.parse(msg))

showmessage(io, msg, logger, mode) = _showmessage(io, msg, logger, mode)
showmessage(io, e::Tuple{Exception,Any}, logger, mode) = showvalue(io, e, logger, mode)
showmessage(io, ex::Exception, logger, mode) = showvalue(io, ex, logger, mode)
showmessage(io, ex::AbstractVector{Union{Ptr{Nothing}, Base.InterpreterIP}}, logger, mode) = Base.show_backtrace(io, ex)

function postprocess(mode, delimiter, iobuf)
    print(iobuf, "\n")
    take!(iobuf)
end

function postprocess(mode::Union{FullSquash, JsonSquash}, delimiter, iobuf)
    buf = take!(iobuf)
    delm = Vector{UInt8}(delimiter)
    res = similar(buf)
    L = length(res)
    j = 1
    @inbounds for (i, c) in pairs(buf)
        c == UInt8('\r') && continue
        if c == UInt8('\n') && i < length(buf)
            for c2 in delm
                if j > L
                    resize!(res, 2*L)
                    L *= 2
                end
                res[j] = c2
                j += 1
            end
            continue
        end
        res[j] = c
        j += 1
    end
    if j > L
        resize!(res, 2*L)
        L *= 2
    end
    res[j] = UInt8('\n')

    resize!(res, j)

    return res
end
