HAS_INPUT := $(shell [ -e ${TAR}_input.json ] && echo 1 || echo 0)

ifeq ($(HAS_INPUT), 1)
	PROG_INPUT := --program_input=$(TAR)_input.json
else
	PROG_INPUT :=
endif

all: run

compile:
	cairo-compile $(TAR).cairo --output=$(TAR)_compiled.json

run: compile
	cairo-run --program=$(TAR)_compiled.json --print_output --layout=small ${PROG_INPUT}

trace: compile
	cairo-run --program=$(TAR)_compiled.json --print_output --layout=small ${PROG_INPUT} --tracer

.phony: all compile run trace
