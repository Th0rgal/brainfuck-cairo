use brainfuck::logic::utils::{
    iter, incr_ptr, decr_ptr, incr_mem, decr_mem, match_closing, match_opening, preprocess
};
use bytes_31::{
    split_bytes31, bytes31_try_from_felt252, BYTES_IN_U128, POW_2_8, one_shift_left_bytes_u128,
    BYTES_IN_BYTES31
};
use traits::{Into, DivRem};

trait ProgramTrait {
    fn check(self: @Array<felt252>);
    fn execute(self: @Array<felt252>, input: Array<u8>) -> Array<u8>;
}

impl ProgramTraitImpl of ProgramTrait {
    fn check(self: @Array<felt252>) {
        let mut brackets_balance: felt252 = 0;
        let (mut _str_len, mut _str, mut _strs) = (0, 0, self.span());
        loop {
            match iter(ref _str_len, ref _str, ref _strs) {
                Option::Some(c) => {
                    if c == '[' {
                        brackets_balance += 1;
                        continue;
                    }
                    if c == ']' {
                        assert(brackets_balance != 0, 'too many closing bracket');
                        brackets_balance -= 1;
                        continue;
                    }
                    if c
                        * (c - '+')
                        * (c - '>')
                        * (c - '<')
                        * (c - '-')
                        * (c - '.')
                        * (c - ',') != 0 {
                        panic_with_felt252('invalid char');
                    }
                },
                Option::None => {
                    assert(brackets_balance == 0, 'missing closing bracket');
                    break;
                }
            };
        };
    }

    fn execute(self: @Array<felt252>, input: Array<u8>) -> Array<u8> {
        let instructions = preprocess(self.span());
        let len = instructions.len();
        let mut memory: Felt252Dict<u8> = Default::default();
        let mut input = input.span();
        let mut output: Array<u8> = Default::default();
        let mut ptr: felt252 = 0;
        let mut pc: usize = 0;

        // iterator
        let mut next_str_id = 0;
        let mut str = 0;
        let mut chars_left = 0;
        loop {
            match instructions.get(pc) {
                Option::Some(char) => {
                    let c = *char.unbox();
                    if c == '>' {
                        incr_ptr(ref ptr);
                    } else if c == '<' {
                        decr_ptr(ref ptr);
                    } else if c == '+' {
                        incr_mem(ref memory, ptr);
                    } else if c == '-' {
                        decr_mem(ref memory, ptr);
                    } else if c == '.' {
                        output.append(memory.get(ptr));
                    } else if c == ',' {
                        memory.insert(ptr, *input.pop_front().unwrap());
                    } else if c == '[' {
                        if memory.get(ptr) == 0 {
                            match_closing(ref pc, @instructions);
                        };
                    } else if c == ']' {
                        if memory.get(ptr) != 0 {
                            match_opening(ref pc, @instructions);
                        };
                    };
                },
                Option::None => {
                    break;
                }
            }
            pc += 1;
        };
        output
    }
}
