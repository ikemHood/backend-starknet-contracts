use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player_address: ContractAddress,
    pub name: felt252,
    pub created_at: u64,
}

#[derive(Model, Copy, Drop, Serde)]
#[dojo::model]
pub struct TournamentParticipant {
    #[key]
    pub tournament_id: u32,
    #[key]
    pub player_address: ContractAddress,
    pub joined_at: u64,
    pub entry_fee_paid: u256,
}
