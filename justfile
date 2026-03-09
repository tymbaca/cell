BUILD_FLAGS := "-collection:src=src -collection:lib=lib"
OUT := "cell.bin"

run:
    odin run src {{BUILD_FLAGS}}

debug:
    odin build src -debug {{BUILD_FLAGS}} -out:{{OUT}} 
    lldb {{OUT}}

update-submodules:
    git submodule update --recursive --remote
