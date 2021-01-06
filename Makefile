all: run

compile:
	cairo-compile $(TARGET).cairo --output=$(TARGET)_compiled.json

run: compile
	cairo-run --program=$(TARGET)_compiled.json --print_output --layout=small --program_input=$(TARGET)_input.json

trace:
	cairo-run --program=$(TARGET)_compiled.json --print_output --layout=small --program_input=$(TARGET)_input.json --tracer

.phony: all compile run trace
