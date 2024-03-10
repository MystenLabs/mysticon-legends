module mysticon_legends::genesis {
    use sui::object::{Self, UID};
    use sui::package::{Self};
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};

    /// The AdminCap is a special capability struct
    /// transferred to the publisher of the contract.
    /// It allows the publisher to perform administrative tasks
    struct AdminCap has key, store {
        id: UID
    }

    /// The GENESIS struct is an One Time Witness Struct
    /// that is used to initialize the Publisher of the contract.
    struct GENESIS has drop {}

    /// The init function is called by the contract publisher
    /// to initialize the contract. It is called only once.
    /// It creates the AdminCap and the Publisher object
    /// and transfers them to the publisher of the contract.
    fun init (otw: GENESIS, ctx: &mut TxContext){

        let publisher = package::claim(otw, ctx);
        // Transfer the Publisher object to the publisher of the contract
        transfer::public_transfer(publisher, sender(ctx));
        // Create the AdminCap and transfer it to the publisher of the contract
        transfer::public_transfer(AdminCap { 
            id: object::new(ctx)}, 
            sender(ctx));
    }

}