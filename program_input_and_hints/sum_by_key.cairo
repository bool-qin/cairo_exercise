%builtins output range_check

from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.dict import DictAccess
from starkware.cairo.common.dict import squash_dict

struct KeyValue:
    member key = 0
    member value = 1
    const SIZE = 2
end

# Builds a DictAccess list for the computation of the cumulative
# sum for each key.
func build_dict(list : KeyValue*, size, dict : DictAccess*) -> (dict : DictAccess*):
    if size == 0:
        return (dict=dict)
    end

    %{
        # Populate ids.dict.prev_value using cumulative_sums
        # Add list.value to cumulative_sums[list.key] ...

        found = 0
        for _i, key in enumerate(cumulative_sums):
            if key == ids.list.key:
                ids.dict.prev_value = cumulative_sums[ids.list.key]
                cumulative_sums[ids.list.key] = ids.dict.prev_value + ids.list.value
                found = 1
                break

        if found == 0:
            ids.dict.prev_value = 0
            cumulative_sums[ids.list.key] = ids.list.value
    %}

    # Copy list.key to dict.key
    # Verify that dict.new_value = dict.prev_value + list.value
    # Call recursively to build_dict()
    assert dict.key = list.key
    assert dict.new_value = dict.prev_value + list.value
    build_dict(list=list + KeyValue.SIZE, size=size - 1, dict=dict + DictAccess.SIZE)
    return (...)
end

# Verifies that the initial values were 0, and writes the final
# values to result.
func verify_and_output_squashed_dict(
    squashed_dict : DictAccess*,
    squashed_dict_end : DictAccess*, result : KeyValue*) -> (
    result: KeyValue*):
    tempvar diff = squashed_dict_end - squashed_dict
    if diff == 0:
        return (result=result)
    end

    # Verify prev_value is 0
    # Copy key to result.key
    # Copy new_value to result.value
    # Call recursively to verify_and_output_squashed_dict
    assert squashed_dict.prev_value = 0
    assert result.key = squashed_dict.key
    assert result.value = squashed_dict.new_value
    verify_and_output_squashed_dict(squashed_dict=squashed_dict + DictAccess.SIZE, squashed_dict_end=squashed_dict_end, result=result + KeyValue.SIZE)

    return (...)
end

# Give a list of KeyValue, sums the values, grouped by key,
# and returns a list of pairs (key, sum_of_values).
func sum_by_key(range_check_ptr, list : KeyValue*, size) -> (
    range_check_ptr, result: KeyValue*, result_size):
    alloc_locals

    %{
        # Initialize cumulative_sums with an empty dictionary.
        # This variable will be used by ``build_dict`` to hold
        # the current sum for each key.
        cumulative_sums = {}
    %}

    # Allocate memory for dict, squashed_dict and res...
    # Call build_dict()
    # Call squashed_dict()
    # Call verify_and_output_squashed_dict()

    let (dict_start) = alloc()
    local dict_start : DictAccess* = dict_start
    let (squashed_dict) = alloc()
    local squashed_dict : DictAccess* = squashed_dict
    let (result) = alloc()
    local result : KeyValue* =result

    let (dict_end) = build_dict(list=list, size=size, dict=dict_start)
    let (local range_check_ptr,
        squashed_dict_end : DictAccess*) = squash_dict(
        range_check_ptr=range_check_ptr,
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict)
    let (result_end) = verify_and_output_squashed_dict(
        squashed_dict=squashed_dict,
        squashed_dict_end=squashed_dict_end,
        result=result)

    local diff = result_end - result
    local result_size = diff / 2

    # Verify that 0 <= result_size <= diff - 1
    let (range_check_ptr) = assert_nn_le(
        range_check_ptr=range_check_ptr, a=result_size, b = diff - 1)
    return (range_check_ptr, result, result_size)
end

func output_result(
    output_ptr : felt*, result : KeyValue*, size) -> (
    output_ptr : felt*):

    if size == 0:
        return (output_ptr=output_ptr)
    end

    assert [output_ptr] = result.key
    assert [output_ptr + 1] = result.value

    output_result(
        output_ptr=output_ptr + KeyValue.SIZE,
        result=result + KeyValue.SIZE,
        size=size - 1)
    return (...)
end

func main(output_ptr : felt*, range_check_ptr) -> (
        output_ptr : felt*, range_check_ptr):
    alloc_locals

    local list : KeyValue*
    local size

    %{
        key_val_pairs = program_input['key_value_pairs']
        size = program_input['size']

        ids.list = list = segments.add()
        for i, val in enumerate(key_val_pairs):
            memory[list + i] = val

        ids.size = size
        print("key value pair size: ", size)
    %}

    let (local range_check_ptr, result: KeyValue*, result_size) = sum_by_key(
        range_check_ptr=range_check_ptr,
        list=list,
        size=size)

    %{
        print("result size: ", ids.result_size)
    %}

    let (output_ptr) = output_result(
        output_ptr=output_ptr,
        result=result,
        size=result_size)

    return (output_ptr=output_ptr, range_check_ptr=range_check_ptr)
end
