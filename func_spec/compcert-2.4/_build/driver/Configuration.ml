let stdlib_path = "/usr/local/lib/compcert"
let prepro = "gcc -arch i386 -U__GNUC__ -U__clang__ -U__BLOCKS__ '-D__attribute__(x)=' -E"
let asm = "gcc -arch i386 -c"
let linker = "gcc -arch i386"
let arch = "ia32"
let model = "sse2"
let abi = "standard"
let system = "macosx"
let has_runtime_lib = true
let asm_supports_cfi = false
let version = "2.4"
