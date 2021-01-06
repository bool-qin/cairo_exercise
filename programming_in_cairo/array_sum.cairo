%builtins output

from starkware.cairo.common.alloc import alloc

func array_sum(arr, size) -> (sum):
    if size == 0:
        return (sum=0)
    end

    let (sum_of_rest) = array_sum(arr=arr + 1, size = size - 1)
    return (sum=[arr] + sum_of_rest)
end

func array_even_entry_multiply(arr, size) -> (multiple):
    if size == 0:
        return (multiple=1)
    end

    if size == 1:
        return (multiple=[arr])
    end

    let (multiple_of_rest) = array_even_entry_multiply(arr + 2, size - 2)
    return (multiple=[arr] * multiple_of_rest)
end

func main(output_ptr) -> (output_ptr):
    alloc_locals
    const ARRAY_SIZE = 3

    # Allocate an array.
    let (ptr) = alloc()
    local ptr : felt = ptr

    # Populate some values in the array.
    assert [ptr] = 9
    assert [ptr + 1] = 16
    assert [ptr + 2] = 25

    # Call array_sum to compute the sum of the elements
    let (sum) = array_sum(arr=ptr, size=ARRAY_SIZE)

    # Write the sum to the program output.
    assert [output_ptr] = sum

    let (multiple) = array_even_entry_multiply(arr=ptr, size=ARRAY_SIZE)
    assert [output_ptr + 1] = multiple

    return (output_ptr=output_ptr + 2)
end
