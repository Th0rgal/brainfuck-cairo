mod logic {
    mod program;
    mod utils;
}

#[starknet::interface]
trait IBrainfuckVM<TContractState> {
    fn deploy(ref self: TContractState, program: Array<felt252>) -> u128;
    fn get_program(self: @TContractState, program_id: u128) -> Array<felt252>;
    fn call(self: @TContractState, program_id: u128, input: Array<u8>) -> Array<u8>;
    fn check(self: @TContractState, program_id: u128, input: Array<u8>);
}

#[starknet::contract]
mod BrainfuckVM {
    use core::array::ArrayTrait;
    use super::IBrainfuckVM;

    use brainfuck::logic::program::{ProgramTrait, ProgramTraitImpl};

    #[external(v0)]
    impl BrainfuckVMImpl of super::IBrainfuckVM<ContractState> {
        fn deploy(ref self: ContractState, mut program: Array<felt252>) -> u128 {
            match program.pop_front() {
                Option::Some(prog_part) => {
                    let part_id = program.len();
                    let prog_id = self.deploy(program);
                    self.prog.write((prog_id, part_id), prog_part);
                    prog_id
                },
                Option::None => {
                    let prog_id = self.prog_len.read();
                    self.prog_len.write(prog_id + 1);
                    prog_id
                }
            }
        }

        fn get_program(self: @ContractState, program_id: u128) -> Array<felt252> {
            self.read_program(program_id, 0)
        }

        fn call(self: @ContractState, program_id: u128, input: Array<u8>) -> Array<u8> {
            self.read_program(program_id, 0).execute(input)
        }

        fn check(self: @ContractState, program_id: u128, input: Array<u8>) {
            self.read_program(program_id, 0).check()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn read_program(self: @ContractState, prog_id: u128, i: usize) -> Array<felt252> {
            let prog_part = self.prog.read((prog_id, i));
            if prog_part == 0 {
                Default::default()
            } else {
                let mut prog = self.read_program(prog_id, i + 1);
                prog.append(prog_part);
                prog
            }
        }
    }

    #[storage]
    struct Storage {
        prog_len: u128,
        prog: LegacyMap<(u128, usize), felt252>,
    }
}
