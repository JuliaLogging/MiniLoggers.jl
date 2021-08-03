module MiniLoggersTest

using ReTest

include("test01_tokenizer.jl")
include("test02_loggerformat.jl")
include("test03_misc.jl")

end # module

MiniLoggersTest.runtests()
