%builtins output range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict import DictAccess
from starkware.cairo.common.dict import squash_dict

struct Location:
    member row = 0
    member col = 1
    const SIZE = 2
end

func verify_valid_location(loc: Location*):
    tempvar row = loc.row
    assert row * (row - 1) * (row - 2) * (row - 3) = 0

    tempvar col = loc.col
    assert col * (col - 1) * (col - 2) * (col - 3) = 0

    return ()
end

func verify_adjacent_locations(
    loc0: Location*, loc1 : Location*):
    alloc_locals
    local row_diff = loc0.row - loc1.row
    local col_diff = loc0.col - loc1.col

    if row_diff == 0:
        assert col_diff * col_diff = 1
        return()
    else:
        assert row_diff * row_diff = 1
        assert col_diff = 0
        return()
    end
end

func verify_location_list(loc_list: Location*, n_steps):
    verify_valid_location(loc=loc_list)

    if n_steps == 0:
        tempvar loc=loc_list
        assert loc.row = 3
        assert loc.col = 3
        return ()
    end

    verify_adjacent_locations(
        loc0=loc_list, loc1=loc_list + Location.SIZE)

    verify_location_list(loc_list=loc_list + Location.SIZE, n_steps=n_steps - 1)
    return ()
end

func build_dict(
    loc_list : Location*, tile_list: felt*, n_steps,
    dict : DictAccess*) -> (dict: DictAccess*):
    if n_steps == 0:
        return (dict=dict)
    end

    # Set the key to the current tile being moved
    assert dict.key = [tile_list]

    # Its previous location should be where the empty tile is
    # going to be.
    let next_loc : Location* = loc_list + Location.SIZE
    assert dict.prev_value = 4 * next_loc.row + next_loc.col

    # Its next location should be where the empty tile is now.
    assert dict.new_value = 4 * loc_list.row + loc_list.col

    let (dict) = build_dict(
        loc_list=next_loc,
        tile_list=tile_list + 1,
        n_steps=n_steps - 1,
        dict=dict + DictAccess.SIZE)
    return (dict=dict)
end

func finalize_state(dict : DictAccess*, idx) -> (
        dict : DictAccess*):
    if idx == 0:
        return (dict=dict)
    end

    assert dict.key = idx
    assert dict.prev_value = idx - 1
    assert dict.new_value = idx - 1

    # Call finalize_state recursively.
    let (dict) = finalize_state(dict=dict + DictAccess.SIZE, idx=idx - 1)
    return (dict=dict)
end

func output_initial_values(
        output_ptr : felt*, squashed_dict : DictAccess*, n) -> (
        output_ptr : felt*):
    if n == 0:
        return (output_ptr=output_ptr)
    end

    assert [output_ptr] = squashed_dict.prev_value

    # Call output_initial_values recursively.
    let (output_ptr) = output_initial_values(
        output_ptr=output_ptr + 1,
        squashed_dict=squashed_dict + DictAccess.SIZE,
        n=n - 1)
    return (output_ptr=output_ptr)
end

func check_solution(
        output_ptr : felt*, range_check_ptr,
        loc_list : Location*, tile_list : felt*, n_steps) -> (
        output_ptr : felt*, range_check_ptr):
    alloc_locals

    # Start by verifying that loc_list is valid.
    verify_location_list(loc_list=loc_list, n_steps=n_steps)

    # Allocate memory for the dict and the squashed dict.
    let (dict_start) = alloc()
    local dict_start : DictAccess* = dict_start
    let (squashed_dict) = alloc()
    local squashed_dict : DictAccess* = squashed_dict

    let (dict_end) = build_dict(
        loc_list=loc_list,
        tile_list=tile_list,
        n_steps=n_steps,
        dict=dict_start)

    let (dict_end) = finalize_state(dict=dict_end, idx=15)

    # Store range_check_ptr in a local variable to make it
    # accessible after the call to output_initial_values().
    let (local range_check_ptr,
        squashed_dict_end : DictAccess*) = squash_dict(
        range_check_ptr=range_check_ptr,
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict)

    # Verify that the squashed dict has exactly 15 entries.
    # This will guarantee that all the values in the tile list
    # are in the range 1-15.
    assert squashed_dict_end - squashed_dict = 15 *
        DictAccess.SIZE

    let (output_ptr) = output_initial_values(
        output_ptr=output_ptr,
        squashed_dict=squashed_dict,
        n=15)

    # Output the initial location of the empty tile.
    assert [output_ptr] = 4 * loc_list.row + loc_list.col

    # Output the number of steps.
    assert [output_ptr + 1] = n_steps

    return (
        output_ptr=output_ptr + 2,
        range_check_ptr=range_check_ptr)
end

func main(output_ptr : felt*, range_check_ptr) -> (
        output_ptr : felt*, range_check_ptr):
    alloc_locals

    local loc0 : Location
    assert loc0.row = 0
    assert loc0.col = 2
    local loc1 : Location
    assert loc1.row = 1
    assert loc1.col = 2
    local loc2 : Location
    assert loc2.row = 1
    assert loc2.col = 3
    local loc3 : Location
    assert loc3.row = 2
    assert loc3.col = 3
    local loc4 : Location
    assert loc4.row = 3
    assert loc4.col = 3

    local tile0 = 3
    local tile1 = 7
    local tile2 = 8
    local tile3 = 12

    # Get the value of the frame pointer register (fp) so that
    # we can use the address of loc0.
    let (__fp__, _) = get_fp_and_pc()
    let (output_ptr, range_check_ptr) = check_solution(
        output_ptr=output_ptr,
        range_check_ptr=range_check_ptr,
        loc_list=&loc0,
        tile_list=&tile0,
        n_steps=4)
    return (
        output_ptr=output_ptr, range_check_ptr=range_check_ptr)
end
