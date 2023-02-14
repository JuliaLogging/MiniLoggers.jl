########################################
# Tokenizer type
########################################
abstract type AbstractTokenizer end

########################################
# Color utils
########################################
struct Color
    c::Union{Symbol, Int}
    isbold::Bool
end
Color() = Color(-1, false)
Color(c::Union{Symbol, Int}) = Color(c, false)
iscolored(c::Color) = c.c != -1 || c.isbold

function colorparse(s)
    i = prevind(s, ncodeunits(s) + 1)
    i1 = i
    i0 = i
    col = Color()
    modifiers = 0
    while i > 0
        c = s[i]
        if c == ':'
            if i0 <= i1
                cs = s[i0:i1]
                if cs == "bold" 
                    col = Color(col.c, true)
                    modifiers += 1
                    i1 = prevind(s, i)
                else
                    intcode = tryparse(Int, cs)
                    code = intcode === nothing ? Symbol(cs) : intcode
                    if haskey(Base.text_colors, code) || code == :func
                        col = Color(code, col.isbold)
                        modifiers += 1
                        i1 = prevind(s, i)
                    end
                end
            end
        elseif c == '}' || c == '{'
            break
        end
        i0 = i
        i = prevind(s, i)
        modifiers == 2 && break
    end

    if iscolored(col) && col.c == -1
        col = Color(:normal, col.isbold)
    end

    return i1, col
end

########################################
# Token utils
########################################
struct Token
    val::String
    c::Color
end
iscolored(t::Token) = iscolored(t.c)
Base.isempty(t::Token) = isempty(t.val)

function Token(val)
    i, col = colorparse(val)
    Token(val[1:i], col)
end

########################################
# tokenizer and auxilary functions
########################################
struct GenericTokenizer <: AbstractTokenizer end

function addtoken!(out, s, i0, i1)
    i0 > i1 && return
    i0 > ncodeunits(s) && return
    token = Token(s[i0:i1])
    isempty(token) && return
    push!(out, token)

    return
end

function recolor!(out, s, i0, i1, tind)
    i0 > ncodeunits(s) && return
    addtoken!(out, s, i0, i1)
    _, col = colorparse(s[i0:i1])
    if iscolored(col)
        for j in tind:length(out)
            iscolored(out[j]) || (out[j] = Token(out[j].val, col))
        end
    end

    return
end

function tokenize!(t::GenericTokenizer, out, s, level = 1, i0 = 1)
    i00 = i0
    i = i0
    i1 = prevind(s, i0)
    tind = length(out) + 1
    while i <= ncodeunits(s)
        c = s[i]
        if c == '{'
            addtoken!(out, s, i0, i1)
            i = tokenize!(t, out, s, level + 1, nextind(s, i))
            i1 = prevind(s, i)
            i0 = i
            continue
        elseif c == '}'
            level == 1 && error("Unexpected } at position $i")
            recolor!(out, s, i0, i1, tind)
            return nextind(s, i)
        end
        i1 = i
        i = nextind(s, i)
    end
    level == 1 || error("Unbalanced { at position $i00")
    recolor!(out, s, i0, i1, tind)

    return i
end

tokenize(v::Vector{Token}) = tokenize(GenericTokenizer(), v)
tokenize(::AbstractTokenizer, v::Vector{Token}) = v
tokenize(s) = tokenize(GenericTokenizer(), s)
function tokenize(tokenizer::AbstractTokenizer, s)
    out = Token[]
    tokenize!(tokenizer, out, s)

    return out
end

########################################
# Tokenizer for JsonLogger
########################################

struct JsonLoggerTokenizer <: AbstractTokenizer end

function addtoken!(t::JsonLoggerTokenizer, out, s, i0, i1, quoted = false)
    if quoted
        addtoken!(t, out, "\"" * s[i0:i1] * "\"")
    else
        addtoken!(t, out, s[i0:i1])
    end
end

function addtoken!(t::JsonLoggerTokenizer, out, s)
    push!(out, Token(s, Color()))
end

function tokenize!(t::JsonLoggerTokenizer, out, s, level = 1, i0 = 1)
    addtoken!(t, out, "{")

    i00 = i0
    i = i0
    i1 = prevind(s, i0)
    tind = length(out) + 1
    duplicate = true
    while i <= ncodeunits(s)
        c = s[i]
        if c == '{'
            i = tokenize!(t, out, s, level + 1, nextind(s, i))
            i0 = i
            i1 = i
            duplicate = true
            continue
        elseif c == '}'
            level == 1 && error("Unexpected } at position $i")
            if i0 <= i1
                if duplicate
                    addtoken!(t, out, s, i0, i1, true)
                    addtoken!(t, out, ":")
                    addtoken!(t, out, s, i0, i1, false)
                else
                    addtoken!(t, out, s, i0, i1, false)
                end
            end
            addtoken!(t, out, "}")
            return nextind(s, i)
        elseif c == ','
            if i0 < i
                if duplicate
                    addtoken!(t, out, s, i0, i1, true)
                    addtoken!(t, out, ":")
                    addtoken!(t, out, s, i0, i1, false)
                else
                    addtoken!(t, out, s, i0, i1, false)
                end
            end
            addtoken!(t, out, ",")
            i0 = nextind(s, i)
            duplicate = true
        elseif c == ':'
            duplicate = false
            addtoken!(t, out, s, i0, i1, true)
            addtoken!(t, out, ":")
            i0 = nextind(s, i)
        end
        i1 = i
        i = nextind(s, i)
    end
    level == 1 || error("Unbalanced { at position $i00")
    if i0 <= ncodeunits(s)
        if duplicate
            addtoken!(t, out, s, i0, i1, true)
            addtoken!(t, out, ":")
            addtoken!(t, out, s, i0, i1, false)
        else
            addtoken!(t, out, s, i0, i1, false)
        end
    end

    addtoken!(t, out, "}")

    return i
end
