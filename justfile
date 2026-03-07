BUILD_FLAGS := "-collection:src=src -collection:lib=lib"

run:
    odin run src {{BUILD_FLAGS}}

submodules-update:
    git submodule update --recursive --remote
