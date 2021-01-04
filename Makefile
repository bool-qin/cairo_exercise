compile:
	cairo-compile program_input_and_hints/sum_by_key.cairo --output=program_input_and_hints/sum_by_key_compiled.json

run:
	cairo-run --program=program_input_and_hints/sum_by_key_compiled.json --print_output --layout=small --program_input=program_input_and_hints/sum_by_key_input.json

trace:
	cairo-run --program=program_input_and_hints/sum_by_key_compiled.json --print_output --layout=small --program_input=program_input_and_hints/sum_by_key_input.json --tracer

all: compile run

.phony: all compile run
