pub mod modules {
    pub mod tournaments {
        pub mod TournamentSystem;
    }
    pub mod players {
        pub mod PlayerSystem;
    }

    pub mod betting {
        pub mod BettingSystem;
    }
}

#[cfg(test)]
mod tests {
    mod test_betting;
}
