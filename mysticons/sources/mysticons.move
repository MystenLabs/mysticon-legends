// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module mysticon_legends::mysticons {
    // === Imports ===
    use std::string::{String};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::transfer::{Self};
    use sui::dynamic_object_field as ofield;

    /// AdminCap is a capability that allows the game's admin to perform privileged operations.
    use mysticon_legends::genesis::{AdminCap};


    // === Errors ===
    const EMysticonIsExported: u64 = 1;
    const EInvalidMysticon: u64 = 2;
    const ENotSufficientPowerLevel: u64 = 3;

    // === Structs ===

    /// A Mysticon is a mythical creature that players can collect, train, and battle with in the game.
    struct Mysticon has key, store {
        // Unique identifier for each Mysticon, automatically generated.
        id: UID,
        // The name of the Mysticon, chosen by the player or assigned upon creation.
        // Possible values: "Frostwing", "Emberflame", "Galeclaw", etc.
        name: String,
        // The elemental type of the Mysticon, determining its affinities and weaknesses.
        // Possible values: "Fire", "Water", "Earth", "Air", "Ice", "Light", "Dark"
        type: String,
        // Represents the Mysticon's overall strength and combat effectiveness.
        // Possible values: 0 to 100, where higher values indicate stronger Mysticons.
        power_level: u8,
        // A unique ability or skill that the Mysticon can use in battles or quests.
        // Possible values: "Ice Storm", "Phoenix Rebirth", "Lightning Strike", "Earthquake", "Healing Aura"
        special_ability: String,
        // Indicates whether the Mysticon is currently undergoing training to improve its abilities.
        // Indicates whether the Mysticon has been exported out of the game's custodial wallet to a player's personal wallet.
        // Possible values: true (currently training), false (not training)
        training_status: bool,
        // URL to an image representing the Mysticon, typically stored on a decentralized file storage service like IPFS.
        // Example value: "ipfs://example_image_url_for_mysticon"
        image_url: String
    }

    /// A GamePass is a digital ticket that allows a player to put his Mysticon back to the game.
    /// The GamePass facilitates the Mysticon's movement between a player's custodial and non-custodial wallets.
    struct GamePass has key, store {
        // Unique identifier for the GamePass. Ensures that each GamePass is distinct and traceable.
        id: UID,
        // Identifies the Mysticon associated with this GamePass. Links the pass directly to a specific Mysticon.
        mysticon_id: ID,
        // Address of the custodial wallet managed by the game. Indicates where the Mysticon should return after being exported.
        custodial_wallet: address
    }

    /// A CompanionCreature is a creature that can be attached
    /// to a Mysticon to enhance its abilities.
    struct CompanionCreature has key, store {
        id: UID,
        name: String,
        description: String,
    }

    /// A hot potato struct to consume the invoice for the creature that is attached to the Mysticon.
    /// The invoice is used to pay for the creature by reducing the power level of the Mysticon.
    struct CreatureInvoice {
        mysticon_id: ID,
        value: u8,
     }
    
    // === Public-Mutative Functions ===

    /// Mints a new Mysticon, automatically enabling training.
    public fun new_mysticon(_: &AdminCap, name: String, type: String,
    power_level: u8, special_ability: String, image_url: String, ctx: &mut TxContext): Mysticon {
        // Create a new Mysticon
        Mysticon {
            id: object::new(ctx),
            name, 
            type,
            power_level,
            special_ability,
            training_status: true,
            image_url,
        }
    }

    /// Enhances a Mysticon's power level through training.
    public fun train_mysticon(mysticon: &mut Mysticon, power_increment: u8, _ctx: &mut TxContext) {
        // Ensure the Mysticon is not exported and is eligible for training
        assert!(mysticon.training_status, EMysticonIsExported);
        mysticon.power_level = mysticon.power_level + power_increment;
    }

    /// Locks a Mysticon for export, marking it as no longer in active training within the game.
    /// This is typically used when a player wants to take their Mysticon outside the game environment,
    /// either for holding or trading with other players.
    public fun lock_mysticon(mysticon: &mut Mysticon, _ctx: &mut TxContext) {
         // Suspends the Mysticon's training status.
         mysticon.training_status = false;
    }

    /// Creates a new GamePass for a Mysticon, enabling its return to the game's ecosystem.
    /// It is issued by the game admin and ties a Mysticon with the player's wallets, preparing it for re-import.
    public fun new_game_pass(_: &mut AdminCap, mysticon_id: ID, custodial_wallet: address, ctx: &mut TxContext
    ): GamePass {
       // Create a new GamePass 
       GamePass {
            id: object::new(ctx),
            mysticon_id,
            custodial_wallet
       }
    }

    /// Imports a Mysticon back into the game's ecosystem using a GamePass.
    /// This function reactivates the Mysticon's training status and transfers it to the game's custodial wallet,
    /// allowing the player to continue engaging with the game using the Mysticon.
    public fun import_mysticon(game_pass: GamePass, mysticon: Mysticon, _ctx: &mut TxContext) {
        // unpack the game_pass
       let GamePass { id, mysticon_id, custodial_wallet } = game_pass;
       // Validate the GamePass
       assert!(mysticon_id == object::id(&mysticon), EInvalidMysticon);
       // Reactivates the Mysticon's training status. 
       mysticon.training_status = true;
       // Transfers the Mysticon to the custodial wallet.
       transfer::public_transfer(mysticon, custodial_wallet);
       // Deletes the used GamePass
       object::delete(id);
    }

    /// Attaches a creature to the Mysticon to enhance its abilities.
    /// The creature is added as a dynamic object field to the Mysticon.
    /// The returned invoice is used to pay for the creature by reducing the power level of the Mysticon.
    /// The invoice is a hot potato and should be consumed after payment for the transaction to be valid.
    public fun attach_creature(mysticon: &mut Mysticon, name: String, description: String, ctx: &mut TxContext): CreatureInvoice {
        // Ensure the Mysticon is not exported and is eligible for training
        assert!(mysticon.training_status, EMysticonIsExported); 
        // Create a new CompanionCreature
        let companionCreature = CompanionCreature{
            id: object::new(ctx),
            name,
            description,
        };
        // Add the creature as a dynamic object field to the Mysticon
        ofield::add(mysticon_uid_mut(mysticon), b"companion_creature", companionCreature);
        let invoice = CreatureInvoice { 
            mysticon_id: object::uid_to_inner(&mysticon.id), 
            value: 50 
        };
        // Return the invoice
        invoice
    }

    /// Pay for the creature that is attached to the Mysticon.
    /// The invoice is used to pay for the creature by reducing the power level of the Mysticon.
    /// The invoice hot potato is consumed by this function.
    public fun pay_invoice(mysticon: &mut Mysticon, invoice: CreatureInvoice) {
        // Unpack the invoice
        let CreatureInvoice { mysticon_id, value } = invoice;
        // Validate the invoice
        assert!(mysticon_id == object::id(mysticon), EInvalidMysticon);
        // Ensure the Mysticon has enough power level to pay for the creature
        assert!(mysticon.power_level >= value, ENotSufficientPowerLevel);
        // Pay for the creature by reducing the power level of the Mysticon
        mysticon.power_level = mysticon.power_level - value;
    }

    /// Check whether Mysticon can be updated.
    // training_status: true` -> can be updated.
    // training_status: false` -> can not be updated.
    public fun mysticon_can_be_updated(mysticon: &Mysticon): bool {
        mysticon.training_status
    }

    /// Get a mutable reference of the UID of the Mysticon
     public fun mysticon_uid_mut(self: &mut Mysticon): &mut UID {
        assert!(mysticon_can_be_updated(self), EMysticonIsExported);
        &mut self.id
    }

    /// Delete a Mysticon object
    /// Needs unpacking
    public fun destroy_mysticon (mysticon: Mysticon) {
        assert!(mysticon.training_status, EMysticonIsExported);
        let Mysticon {
            id,
            name: _,
            type: _,
            power_level: _,
            special_ability: _,
            training_status: _,
            image_url: _,
        } = mysticon;
        
        object::delete(id);
    }
    
}