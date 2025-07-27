use starknet::ContractAddress;

// ========================================
// CONTRACT INTERFACE - Betting System
// ========================================

#[starknet::interface]
pub trait IBettingSystem<TContractState> {
    
    fn get_active_bet_pools(
        self: @TContractState,
    ) -> Array<BetPool>; 
 
}

// ========================================
// DATA STRUCTURES
// ========================================

#[derive(Drop, Serde, starknet::Store)]
 struct BetPool {
    pub pool_id: u64,
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
    use starknet::ContractAddress;
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
    }

    // Contract events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PoolCreated: PoolCreated,
        PoolClosed: PoolClosed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PoolCreated {
        #[key]
        pub pool_id: u64,
        pub creator: ContractAddress,
        pub name: ByteArray,
        pub total_amount: u256,
        pub closes_at: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PoolClosed {
        #[key]
        pub pool_id: u64,
        pub closed_at: u64,
    }

    // Contract implementation
    #[abi(embed_v0)]
    pub impl BettingSystemImpl of IBettingSystem<ContractState> {
       
        // Get all active pools (view function)
        fn get_active_bet_pools(
            self: @ContractState,
        ) -> Array<BetPool> {
            let mut active_pools = ArrayTrait::new();
            let active_ids_len = self.active_pool_ids.len();
            
            let mut i = 0;
            loop {
                if i >= active_ids_len {
                    break;
                }
                
                let pool_id = self.active_pool_ids.at(i).read();
                let pool = self.pools.read(pool_id);
                let status = self.pool_status.read(pool_id);
                
                // Filter by is_open == true as required
                if pool.is_open && status.is_active {
                    active_pools.append(pool);
                }
                
                i += 1;
            };
            
            active_pools
        }
        
       
    }
    
} 