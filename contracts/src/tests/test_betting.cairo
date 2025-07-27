use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, load, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_block_timestamp,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};
use crate::modules::betting::BettingSystem::BettingSystem::BetPoolCreated;
use crate::modules::betting::BettingSystem::{
    BettingSystem, IBettingSystem, IBettingSystemDispatcher, IBettingSystemDispatcherTrait,
};


// Helper function to deploy the contract
// Assuming a constructor with no arguments for the BettingSystem contract,
fn deploy_contract() -> IBettingSystemDispatcher {
    let contract = declare("BettingSystem").unwrap();
    let owner_address: ContractAddress = contract_address_const::<'owner'>();
    let args = array![owner_address.into()];
    let (contract_address, _err) = contract.contract_class().deploy(@args).unwrap();
    IBettingSystemDispatcher { contract_address }
}

#[test]
fn test_create_bet_pool_success() {
    let dispatcher = deploy_contract();
    let mut spy = spy_events();

    // Setup caller address cheat
    let caller_address = contract_address_const::<'owner'>();
    start_cheat_caller_address(dispatcher.contract_address, caller_address);

    // Setup block timestamp cheat to control `closes_at` assertion
    let current_timestamp = 1000_u64;
    start_cheat_block_timestamp(dispatcher.contract_address, current_timestamp);

    // Define parameters for a valid bet pool
    let tournament_id = 1_u64;
    let match_id = 101_u64;
    let name = 'FootballMatch';
    let description: ByteArray = "World Cup Final";
    let min_bet = 10;
    let max_bet = 200;
    let closes_at = current_timestamp + 100_u64; // Must be in the future
    let category = 'Sports';
    let mut outcomes = array![];
    outcomes.append('TeamA_Wins');
    outcomes.append('Draw');
    outcomes.append('TeamB_Wins');

    // Get initial state of total_pools
    let initial_total_pools = dispatcher.get_total_pools();
    assert(initial_total_pools == 0, 'Initial should be 0');

    // Call the function to create a new bet pool
    let pool_id = dispatcher
        .create_bet_pool(
            tournament_id,
            match_id,
            name,
            description,
            min_bet,
            max_bet,
            closes_at,
            category,
            outcomes,
        );

    // Assert the returned pool_id is correct (first pool should be 1)
    assert(pool_id == 1, 'Pool ID should be 1');

    // Verify total_pools counter increased
    let total_pools_after = dispatcher.get_total_pools();
    assert_eq!(total_pools_after, 1, "total_pools should be 1 now");

    // Verify event emission
    let expected_event = BettingSystem::Event::BetPoolCreated(
        BetPoolCreated {
            pool_id: 1, tournament_id, match_id, name, closes_at, creator: caller_address,
        },
    );
    spy.assert_emitted(@array![(dispatcher.contract_address, expected_event)]);
}

#[test]
#[should_panic(expected: 'CALLER_NOT_OWNER')]
fn test_create_bet_pool_not_owner() {
    let dispatcher = deploy_contract();
    let caller_address = contract_address_const::<'non_owner'>();
    start_cheat_caller_address(dispatcher.contract_address, caller_address);
    let current_timestamp = 1000_u64;
    start_cheat_block_timestamp(dispatcher.contract_address, current_timestamp);

    let tournament_id = 1_u64;
    let match_id = 101_u64;
    let name = 'FootballMatch';
    let description: ByteArray = "Invalid Bet Limits Test";
    let min_bet = 50;
    let max_bet = 50;
    let closes_at = current_timestamp + 100_u64;
    let category = 'Sports';
    let mut outcomes = array![];
    outcomes.append('OutcomeA');

    dispatcher
        .create_bet_pool(
            tournament_id,
            match_id,
            name,
            description,
            min_bet,
            max_bet,
            closes_at,
            category,
            outcomes,
        );
}


#[test]
#[should_panic(expected: 'INVALID_BET_LIMITS')]
fn test_create_bet_pool_invalid_bet_limits() {
    let dispatcher = deploy_contract();
    let caller_address = contract_address_const::<'owner'>();
    start_cheat_caller_address(dispatcher.contract_address, caller_address);
    let current_timestamp = 1000_u64;
    start_cheat_block_timestamp(dispatcher.contract_address, current_timestamp);

    let tournament_id = 1_u64;
    let match_id = 101_u64;
    let name = 'FootballMatch';
    let description: ByteArray = "Invalid Bet Limits Test";
    let min_bet = 50;
    let max_bet = 50;
    let closes_at = current_timestamp + 100_u64;
    let category = 'Sports';
    let mut outcomes = array![];
    outcomes.append('OutcomeA');

    dispatcher
        .create_bet_pool(
            tournament_id,
            match_id,
            name,
            description,
            min_bet,
            max_bet,
            closes_at,
            category,
            outcomes,
        );
}

#[test]
#[should_panic(expected: 'NO_OUTCOMES_PROVIDED')]
fn test_create_bet_pool_no_outcomes() {
    let dispatcher = deploy_contract();
    let caller_address = contract_address_const::<'owner'>();
    start_cheat_caller_address(dispatcher.contract_address, caller_address);
    let current_timestamp = 1000_u64;
    start_cheat_block_timestamp(dispatcher.contract_address, current_timestamp);

    let tournament_id = 1_u64;
    let match_id = 101_u64;
    let name = 'FootballMatch';
    let mut description = "Banditss";
    let min_bet = 10;
    let max_bet = 110;
    let closes_at = current_timestamp + 100_u64;
    let category = 'Sports';
    let outcomes = array![];

    dispatcher
        .create_bet_pool(
            tournament_id,
            match_id,
            name,
            description,
            min_bet,
            max_bet,
            closes_at,
            category,
            outcomes,
        );
}

#[test]
#[should_panic(expected: 'POOL_CLOSES_IN_PAST')]
fn test_create_bet_pool_closes_in_past() {
    let dispatcher = deploy_contract();
    let caller_address = contract_address_const::<'owner'>();
    start_cheat_caller_address(dispatcher.contract_address, caller_address);
    let current_timestamp = 1000_u64;
    start_cheat_block_timestamp(dispatcher.contract_address, current_timestamp);

    let tournament_id = 1_u64;
    let match_id = 101_u64;
    let name = 'FootballMatch';
    let mut description: ByteArray = "Closes In Past Test";
    let min_bet = 10;
    let max_bet = 250;
    let closes_at = current_timestamp - 1_u64;
    let category = 'Sports';
    let mut outcomes = array![];
    outcomes.append('OutcomeA');

    dispatcher
        .create_bet_pool(
            tournament_id,
            match_id,
            name,
            description,
            min_bet,
            max_bet,
            closes_at,
            category,
            outcomes,
        );
}
