module mysticon_legends::genesis {

    // === Imports ===
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    // === Structs ===

    /// The AdminCap is a special capability struct
    /// transferred to the publisher of the contract.
    /// It allows the publisher to perform administrative tasks
     struct AdminCap has key, store {
        id: UID
    }
    
    /// The init function is called by the contract publisher
    /// to initialize the contract. It is called only once.
    /// It creates the AdminCap and and transfers it to the publisher of the contract.
    fun init(ctx: &mut TxContext){
        let adminCap = AdminCap { id: object::new(ctx) };
        // Create the AdminCap and transfer it to the publisher of the contract
        transfer::public_transfer(adminCap, tx_context::sender(ctx));

    }
    
}