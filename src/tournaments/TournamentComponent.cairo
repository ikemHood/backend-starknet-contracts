use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Tournament {
    #[key]
    pub tournament_id: u32,
    pub name: felt252,
    pub organizer: ContractAddress,
    pub start_time: u64,
    pub end_time: u64,
    pub status: felt252, // 'upcoming', 'active', 'completed', 'cancelled'
    pub max_teams: u32,
    pub current_teams: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TournamentOrganizer {
    #[key]
    pub tournament_id: u32,
    #[key]
    pub organizer: ContractAddress,
    pub role: felt252, // 'main_organizer', 'co_organizer', 'referee'
    pub permissions: u32, // Bitfield for permissions
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Match {
    #[key]
    pub match_id: u32,
    pub tournament_id: u32,
    pub team1_id: u32,
    pub team2_id: u32,
    pub team1_score: u32,
    pub team2_score: u32,
    pub status: felt252, // 'scheduled', 'in_progress', 'completed', 'cancelled'
    pub scheduled_time: u64,
    pub completed_time: u64,
    pub recorded_by: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct MatchParticipation {
    #[key]
    pub tournament_id: u32,
    #[key]
    pub team_id: u32,
    pub is_participating: bool,
    pub joined_at: u64,
}

// Permission constants
pub const PERMISSION_RECORD_MATCH: u32 = 1; // 0001
pub const PERMISSION_MANAGE_TEAMS: u32 = 2; // 0010
pub const PERMISSION_MANAGE_TOURNAMENT: u32 = 4; // 0100
