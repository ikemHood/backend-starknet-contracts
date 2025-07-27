use starknet::ContractAddress;

// ========================================
// CONTRACT INTERFACE - Betting System
// ========================================

#[starknet::interface]
pub trait IBettingSystem<TContractState> {
    
    fn create_bet_pool(
        ref self: TContractState,
        tournament_id: u64,
        match_id: u64,
        name: felt252,
        description: ByteArray,
        min_bet: u256,
        max_bet: u256,
        closes_at: u64,
        category: felt252,
        outcomes: Array<felt252>
    ) -> u64;
 
}

// ========================================
// DATA STRUCTURES
// ========================================

#[derive(Drop, Serde, starknet::Store)]
 struct BetPool {
    pub pool_id: u64,
    pub tournament_id: u64,
    pub match_id: u64,
    pub name: felt252,
    pub description: ByteArray,
    pub total_amount: u256,
    pub min_bet: u256,
    pub max_bet: u256,
    pub created_at: u64,
    pub closes_at: u64,
    pub is_open: bool,
    pub creator: ContractAddress,
    pub total_bets: u32,
    pub category: felt252,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct BetDetails {
    pub bettor: ContractAddress,
    pub pool_id: u64,
    pub predicted_outcome: felt252,
    pub amount: u256,
    pub placed_at: u64,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct PoolStatus {
    pub pool_id: u64,
    pub is_active: bool,
    pub last_updated: u64,
}

// ========================================
// MAIN CONTRACT - Betting System
// ========================================

#[starknet::contract]
pub mod BettingSystem {
    use super::{BetPool, PoolStatus, IBettingSystem};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::*;

    // Contract storage
    #[storage]
    pub struct Storage {
        // Total pools counter
        total_pools: u64,
        
        // Pools mapping by ID
        pools: Map<u64, BetPool>,
        
        // Status mapping by ID
        pool_status: Map<u64, PoolStatus>,
        
        // Active pools list for efficient querying
        active_pool_ids: Vec<u64>,

        // Stores outcomes for each pool
        outcomes_per_pool: Map<u64, Vec<felt252>>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        BetPoolCreated: BetPoolCreated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BetPoolCreated {
        #[key]
        pub pool_id: u64,
        #[key]
        pub tournament_id: u64,
        pub match_id: u64,
        pub name: felt252,
        pub closes_at: u64,
        #[key]
        pub creator: ContractAddress,
    }


    #[abi(embed_v0)]
    pub impl BettingSystemImpl of IBettingSystem<ContractState> {
       
        // Create a new bet pool
        fn create_bet_pool(
            ref self: ContractState,
            tournament_id: u64,
            match_id: u64,
            name: felt252,
            description: ByteArray,
            min_bet: u256,
            max_bet: u256,
            closes_at: u64,
            category: felt252,
            outcomes: Array<felt252>
        ) -> u64 {
            assert(min_bet <= max_bet, 'INVALID_BET_LIMITS');
            assert(!outcomes.is_empty(), 'NO_OUTCOMES_PROVIDED');

            let current_timestamp = get_block_timestamp();
            assert(closes_at > current_timestamp, 'POOL_CLOSES_IN_PAST');


            let pool_id = self.total_pools.read() + 1;
            let creator = get_caller_address();
            
            // Create new BetPool instance
            let new_pool = BetPool {
                pool_id,
                tournament_id,
                match_id,
                name,
                description,
                total_amount: 0,
                min_bet,
                max_bet,
                created_at: current_timestamp,
                closes_at,
                is_open: true,
                creator,
                total_bets: 0,
                category
            };
            
            // Store the new pool
            self.pools.write(pool_id, new_pool);
            
            // Update total pools counter
            self.total_pools.write(pool_id);
            
            // Add to active pools list
            self.active_pool_ids.push(pool_id);
            
            // Store outcomes for the pool

            let mut outcomes_vec_entry = self.outcomes_per_pool.entry(pool_id);

            // Iterate over the elements of the memory array 'outcomes'
            let outcomes_len = outcomes.len();
            let mut i = 0;
            loop {
                if i == outcomes_len {
                    break;
                }
                let outcome_element = outcomes.at(i);
                outcomes_vec_entry.push(*outcome_element);
                i += 1;
            };
            
            // Emit event
            self.emit(
                Event::BetPoolCreated(
                    BetPoolCreated {
                        pool_id,
                        tournament_id,
                        match_id,
                        name,
                        closes_at,
                        creator,
                    }
                )
            );
            
            pool_id
        }
        
       
    }
    
} 