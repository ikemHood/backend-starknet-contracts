use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::event]
pub struct TournamentCreated {
    #[key]
    pub tournament_id: u32,
    pub name: felt252,
    pub organizer: ContractAddress,
    pub start_time: u64,
    pub end_time: u64,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct MatchResultRecorded {
    #[key]
    pub match_id: u32,
    #[key]
    pub tournament_id: u32,
    pub team1_id: u32,
    pub team2_id: u32,
    pub team1_score: u32,
    pub team2_score: u32,
    pub recorded_by: ContractAddress,
    pub recorded_at: u64,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct TeamJoinedTournament {
    #[key]
    pub tournament_id: u32,
    #[key]
    pub team_id: u32,
    pub joined_at: u64,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct PlayerJoinedTournament {
    #[key]
    pub tournament_id: u32,
    #[key]
    pub player_address: ContractAddress,
    pub entry_fee_paid: u256,
    pub joined_at: u64,
}
