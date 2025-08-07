use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use contracts::players::PlayerComponent::{Player, TournamentParticipant};
use contracts::tournaments::TournamentComponent::Tournament;
use contracts::tournaments::TournamentEvents::PlayerJoinedTournament;

// Errors
const TOURNAMENT_NOT_FOUND: felt252 = 'Tournament not found';
const TOURNAMENT_NOT_ACTIVE: felt252 = 'Tournament not active';
const TOURNAMENT_FULL: felt252 = 'Tournament is full';
const ALREADY_JOINED: felt252 = 'Already joined tournament';
const INSUFFICIENT_ENTRY_FEE: felt252 = 'Insufficient entry fee';

#[dojo::interface]
trait IPlayerSystem {
    fn join_tournament(
        ref world: IWorldDispatcher,
        tournament_id: u32,
    );
}

#[dojo::contract]
mod player_system {
    use super::*;

    #[abi(embed_v0)]
    impl PlayerSystemImpl of super::IPlayerSystem<ContractState> {
        fn join_tournament(
            ref world: IWorldDispatcher,
            tournament_id: u32,
        ) {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let contract_address = get_contract_address();

            // Validate tournament exists and is active
            let mut tournament: Tournament = get!(world, tournament_id, Tournament);
            assert(tournament.tournament_id == tournament_id, TOURNAMENT_NOT_FOUND);
            assert(tournament.status == 'active' || tournament.status == 'upcoming', TOURNAMENT_NOT_ACTIVE);

            // Check if tournament has capacity
            assert(tournament.current_teams < tournament.max_teams, TOURNAMENT_FULL);

            // Check if player already joined
            let existing_participant: TournamentParticipant = get!(world, (tournament_id, caller), TournamentParticipant);
            assert(existing_participant.player_address.is_zero(), ALREADY_JOINED);

            // Handle entry fee transfer if required
            let entry_fee = tournament.entry_fee;
            if entry_fee > 0 {
                assert(!tournament.fee_token.is_zero(), 'Fee token not set');
                
                // Create ERC20 dispatcher for the fee token
                let token = IERC20Dispatcher { contract_address: tournament.fee_token };
                
                // Check player has sufficient balance
                let player_balance = token.balance_of(caller);
                assert(player_balance >= entry_fee, INSUFFICIENT_ENTRY_FEE);
                
                // Check contract has sufficient allowance to transfer tokens
                let allowance = token.allowance(caller, contract_address);
                assert(allowance >= entry_fee, 'Insufficient allowance');
                
                // Transfer entry fee from player to tournament organizer
                let success = token.transfer_from(caller, tournament.organizer, entry_fee);
                assert(success, 'Entry fee transfer failed');
            }
            
            // Create tournament participant record
            let participant = TournamentParticipant {
                tournament_id,
                player_address: caller,
                joined_at: current_time,
                entry_fee_paid: entry_fee,
            };

            // Update tournament participant count
            tournament.current_teams += 1;

            // Save models
            set!(world, (participant));
            set!(world, (tournament));

            // Emit event
            emit!(world, PlayerJoinedTournament {
                tournament_id,
                player_address: caller,
                entry_fee_paid: entry_fee,
                joined_at: current_time,
            });
        }
    }
}
