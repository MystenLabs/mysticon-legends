module mysticon_legends::genesis {

    // === Imports ===
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::package::{Self};

    // === Structs ===

    /// The AdminCap is a special capability struct
    /// transferred to the publisher of the contract.
    /// It allows the publisher to perform administrative tasks


    // OTW to create the publisher

    
    /// The init function is called by the contract publisher
    /// to initialize the contract. It is called only once.
    /// It creates the AdminCap and and transfers it to the publisher of the contract.
    fun init(otw: GENESIS, ctx: &mut TxContext){

        // Claim the Publisher for the Package
      

        // Transfer the Publisher to the sender
       
        // Create the AdminCap and transfer it to the publisher of the contract


    }
    
}