use dojo::test_utils::{spawn_test_world, deploy_contract};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

use super::super::modules::players::PlayerComponent::{Player, TournamentParticipant};
use super::super::modules::players::PlayerSystem::{IPlayerSystemDispatcher, IPlayerSystemDispatcherTrait};
use super::super::modules::tournaments::TournamentComponent::Tournament;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// Mock ERC20 contract using OpenZeppelin
#[starknet::contract]
mod MockERC20 {
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc20.initializer("MockToken", "MTK");
    }

    #[generate_trait]
    #[abi(embed_v0)]
    impl MockHelpers of MockHelpersTrait {
        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.erc20._mint(to, amount);
        }
    }
}

fn setup_world() -> (IWorldDispatcher, IPlayerSystemDispatcher, ContractAddress, ContractAddress, ContractAddress) {
    // Deploy world and contract
    let mut models = array![
        Player::TEST_CLASS_HASH,
        TournamentParticipant::TEST_CLASS_HASH,
        Tournament::TEST_CLASS_HASH
    ];
    
    let world = spawn_test_world(models);
    
    let contract_address = world.deploy_contract('salt', PlayerSystem::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
    let player_system = IPlayerSystemDispatcher { contract_address };
    
    // Deploy mock ERC20 token
    let token_address = world.deploy_contract('token_salt', MockERC20::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
    
    let player = contract_address_const::<0x123>();
    let organizer = contract_address_const::<0x456>();
    
    (world, player_system, player, organizer, token_address)
}

#[test]
#[available_gas(20000000)]
fn test_join_tournament_success() {
    let (world, player_system, player, organizer, token_address) = setup_world();
    
    // Setup tournament with entry fee
    let tournament = Tournament {
        tournament_id: 1,
        name: 'Test Tournament',
        organizer,
        start_time: 1000,
        end_time: 2000,
        status: 'active',
        max_teams: 10,
        current_teams: 0,
        entry_fee: 100_u256,
        fee_token: token_address,
    };
    
    // Setup player with tokens and allowance
    let token = IERC20Dispatcher { contract_address: token_address };
    let mock_token = IMockERC20Dispatcher { contract_address: token_address };
    
    // Mint tokens to player
    mock_token.mint(player, 1000_u256);
    
    // Player approves contract to spend tokens
    starknet::testing::set_caller_address(player);
    token.approve(player_system.contract_address, 100_u256);
    
    // Save tournament to world
    set!(world, (tournament));
    
    // Join tournament
    player_system.join_tournament(world, 1);
    
    // Verify participant was created
    let participant: TournamentParticipant = get!(world, (1, player), TournamentParticipant);
    assert(participant.tournament_id == 1, 'Wrong tournament ID');
    assert(participant.player_address == player, 'Wrong player address');
    assert(participant.entry_fee_paid == 100_u256, 'Wrong entry fee');
    
    // Verify tournament participant count updated
    let updated_tournament: Tournament = get!(world, 1, Tournament);
    assert(updated_tournament.current_teams == 1, 'Participant count not updated');
    
    // Verify tokens were transferred
    assert(token.balance_of(player) == 900_u256, 'Player tokens not deducted');
    assert(token.balance_of(organizer) == 100_u256, 'Organizer did not receive tokens');
}

#[test]
#[available_gas(20000000)]
fn test_join_tournament_no_fee() {
    let (world, player_system, player, organizer, token_address) = setup_world();
    
    // Setup tournament with no entry fee
    let tournament = Tournament {
        tournament_id: 1,
        name: 'Free Tournament',
        organizer,
        start_time: 1000,
        end_time: 2000,
        status: 'active',
        max_teams: 10,
        current_teams: 0,
        entry_fee: 0_u256,
        fee_token: contract_address_const::<0>(),
    };
    
    set!(world, (tournament));
    
    starknet::testing::set_caller_address(player);
    player_system.join_tournament(world, 1);
    
    // Verify participant was created
    let participant: TournamentParticipant = get!(world, (1, player), TournamentParticipant);
    assert(participant.tournament_id == 1, 'Wrong tournament ID');
    assert(participant.entry_fee_paid == 0_u256, 'Should be no fee');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Tournament not found',))]
fn test_join_nonexistent_tournament() {
    let (world, player_system, player, _organizer, _token_address) = setup_world();
    
    starknet::testing::set_caller_address(player);
    player_system.join_tournament(world, 999); // Non-existent tournament
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Tournament is full',))]
fn test_join_full_tournament() {
    let (world, player_system, player, organizer, token_address) = setup_world();
    
    // Setup tournament at capacity
    let tournament = Tournament {
        tournament_id: 1,
        name: 'Full Tournament',
        organizer,
        start_time: 1000,
        end_time: 2000,
        status: 'active',
        max_teams: 1,
        current_teams: 1, // Already at capacity
        entry_fee: 0_u256,
        fee_token: contract_address_const::<0>(),
    };
    
    set!(world, (tournament));
    
    starknet::testing::set_caller_address(player);
    player_system.join_tournament(world, 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Already joined tournament',))]
fn test_join_tournament_twice() {
    let (world, player_system, player, organizer, token_address) = setup_world();
    
    let tournament = Tournament {
        tournament_id: 1,
        name: 'Test Tournament',
        organizer,
        start_time: 1000,
        end_time: 2000,
        status: 'active',
        max_teams: 10,
        current_teams: 0,
        entry_fee: 0_u256,
        fee_token: contract_address_const::<0>(),
    };
    
    set!(world, (tournament));
    
    starknet::testing::set_caller_address(player);
    
    // Join first time
    player_system.join_tournament(world, 1);
    
    // Try to join again - should fail
    player_system.join_tournament(world, 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Insufficient balance',))]
fn test_join_tournament_insufficient_balance() {
    let (world, player_system, player, organizer, token_address) = setup_world();
    
    let tournament = Tournament {
        tournament_id: 1,
        name: 'Expensive Tournament',
        organizer,
        start_time: 1000,
        end_time: 2000,
        status: 'active',
        max_teams: 10,
        current_teams: 0,
        entry_fee: 1000_u256,
        fee_token: token_address,
    };
    
    set!(world, (tournament));
    
    // Player has no tokens but tournament requires fee
    starknet::testing::set_caller_address(player);
    player_system.join_tournament(world, 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Insufficient allowance',))]
fn test_join_tournament_insufficient_allowance() {
    let (world, player_system, player, organizer, token_address) = setup_world();
    
    let tournament = Tournament {
        tournament_id: 1,
        name: 'Test Tournament',
        organizer,
        start_time: 1000,
        end_time: 2000,
        status: 'active',
        max_teams: 10,
        current_teams: 0,
        entry_fee: 100_u256,
        fee_token: token_address,
    };
    
    let mock_token = IMockERC20Dispatcher { contract_address: token_address };
    mock_token.mint(player, 1000_u256); // Player has tokens
    
    set!(world, (tournament));
    
    // Player doesn't approve contract - should fail
    starknet::testing::set_caller_address(player);
    player_system.join_tournament(world, 1);
}
