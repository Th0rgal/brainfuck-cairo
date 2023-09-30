use traits::{TryInto, DivRem};
use bytes_31::{
    split_bytes31, bytes31_try_from_felt252, BYTES_IN_U128, POW_2_8, one_shift_left_bytes_u128,
    BYTES_IN_BYTES31
};

// returns next_char and updated str_length, str, next_strs
fn iter(ref str_len: usize, ref str: felt252, ref next_strs: Span<felt252>) -> Option<felt252> {
    // we ensure there is a string to read
    if str_len == 0 {
        match next_strs.pop_front() {
            Option::Some(new_str) => {
                str_len = 31;
                str = *new_str;
            },
            Option::None => {
                return Option::None;
            },
        };
    };
    let new_str_len = str_len - 1;
    let (new_str, char) = split_bytes31(str, str_len, new_str_len);
    str_len = new_str_len;
    str = new_str;
    Option::Some(char)
}

fn preprocess(mut program: Span<felt252>) -> Array<u128> {
    if program.len() == 0 {
        return Default::default();
    }
    let str_opt = program.pop_back();
    let mut arr = preprocess(program);

    let u256{low, high } = match str_opt {
        Option::Some(str) => {
            (*str).into()
        },
        Option::None => {
            return arr;
        }
    };
    rec_add_chars(ref arr, 15, high);
    rec_add_chars(ref arr, 16, low);
    return arr;
}

fn rec_add_chars(ref arr: Array<u128>, str_len: felt252, str: u128) {
    if str_len == 0 {
        return;
    }
    let (str, char) = DivRem::div_rem(str, 256_u128.try_into().unwrap());
    rec_add_chars(ref arr, str_len - 1, str);
    if char != 0 {
        arr.append(char);
    }
}

fn incr_ptr(ref ptr: felt252) {
    if ptr == 255 {
        ptr = 0
    } else {
        ptr += 1;
    }
}

fn decr_ptr(ref ptr: felt252) {
    if ptr == 0 {
        ptr = 255
    } else {
        ptr -= 1;
    }
}

fn incr_mem(ref memory: Felt252Dict<u8>, ptr: felt252) {
    let current_value = memory.get(ptr);
    memory.insert(ptr, if current_value == 255 {
        0
    } else {
        current_value + 1
    });
}

fn decr_mem(ref memory: Felt252Dict<u8>, ptr: felt252) {
    let current_value = memory.get(ptr);
    memory.insert(ptr, if current_value == 0 {
        255
    } else {
        current_value - 1
    });
}

fn match_closing(ref pc: usize, instructions: @Array<u128>) {
    let mut count = 0;
    loop {
        pc += 1;
        let c = *instructions.at(pc);
        if c == ']' {
            if count == 0 {
                break;
            };
            count -= 1;
        } else if c == '[' {
            count += 1;
        };
    };
}

fn match_opening(ref pc: usize, instructions: @Array<u128>) {
    let mut count = 0;
    loop {
        pc -= 1;
        let c = *instructions.at(pc);
        if c == '[' {
            if count == 0 {
                break;
            };
            count -= 1;
        } else if c == ']' {
            count += 1;
        };
    };
}
