use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Team {
    #[key]
    pub team_id: u32,
    pub name: felt252,
    pub tournament_id: u32,
    pub captain: ContractAddress,
    pub is_active: bool,
    pub wins: u32,
    pub losses: u32,
    pub draws: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TeamMember {
    #[key]
    pub team_id: u32,
    #[key]
    pub player_address: ContractAddress,
    pub role: felt252, // 'captain', 'player', 'substitute'
    pub joined_at: u64,
}
