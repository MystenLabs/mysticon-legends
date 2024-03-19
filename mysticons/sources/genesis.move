// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module mysticon_legends::genesis {

    // === Imports ===
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::package::{Self, Publisher};

    // === Constants ===
    const ECallerNotPublisher: u64 = 1;

    // === Structs ===

    /// The AdminCap is a special capability struct
    /// transferred to the publisher of the contract.
    /// It allows the publisher to perform administrative tasks
     struct AdminCap has key, store {
        id: UID
    }

    /// OTW to create the publisher
    /// The GENESIS struct is used to create the publisher of the contract.
    struct GENESIS has drop {}
    
    /// The init function is called by the contract publisher
    /// to initialize the contract. It is called only once.
    /// It creates the AdminCap and and transfers it to the publisher of the contract.
    fun init(otw: GENESIS, ctx: &mut TxContext){

        // Claim the Publisher for the Package
        let publisher = package::claim(otw, ctx);

        // Transfer the Publisher to the sender
        transfer::public_transfer(publisher, sender(ctx));

        let adminCap = AdminCap { id: object::new(ctx) };
        // Create the AdminCap and transfer it to the publisher of the contract
        transfer::public_transfer(adminCap, tx_context::sender(ctx));

    }

    /// Only publisher can call this function
    /// to make an address an admin of the contract
    public fun make_address_admin(publisher: &Publisher, new_admin: address, ctx: &mut TxContext) {
        let is_package_publisher = package::from_module<AdminCap>(publisher);
        assert!(is_package_publisher, ECallerNotPublisher);
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::public_transfer(admin_cap, new_admin);
    } 
    
}