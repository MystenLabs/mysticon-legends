module mysticon_legends::mysticons {
    // === Imports ===
    use std::string::{String};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::transfer::{Self};
    use sui::tx_context::{Self};

    /// AdminCap is a capability that allows the game's admin to perform privileged operations.
    use mysticon_legends::genesis::{AdminCap};

    const EMysticonIsExported: u64 = 1;
    const EInvalidMysticon: u64 = 2;

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
        image_url: String,
        // The address of the current owner of the Mysticon
        owner: address,
    }

    /// A QuestPass is a digital ticket that allows a player to embark on a quest with a specific Mysticon.
    struct QuestPass has key, store {
    // Unique identifier for the QuestPass. Ensures that each QuestPass is distinct and traceable.
    id: UID,
    // Identifies the Mysticon associated with this QuestPass. Links the pass directly to a specific Mysticon.
    mysticon_id: ID,
    // Address of the custodial wallet managed by the game. Indicates where the Mysticon should return after being exported.
    custodial_wallet: address,
    }

    // === Public-Mutative Functions ===

    // Mints a new Mysticon, automatically enabling training.
    public fun mint_mysticon(
        _: &mut AdminCap, name: String, type: String,
        power_level: u8, special_ability: String, image_url: String,
        ctx: &mut TxContext
    ): Mysticon {
        Mysticon {
            id: object::new(ctx),
            name,
            type,
            power_level,
            special_ability,
            training_status: true, // Starts with training enabled
            image_url,
            owner: tx_context::sender(ctx),
        }
    }

    // Enhances a Mysticon's power level through training.
    public fun train_mysticon(mysticon: &mut Mysticon, power_increment: u8, _ctx: &mut TxContext) {
        // Ensure the Mysticon is not exported and is eligible for training
        assert!(mysticon.training_status, EMysticonIsExported);
        mysticon.power_level = mysticon.power_level + power_increment;
    }

    // Locks a Mysticon for export, marking it as no longer in active training within the game.
    // This is typically used when a player wants to take their Mysticon outside the game environment,
    // either for holding or trading with other players.
    public fun lock_mysticon(mysticon: &mut Mysticon, _ctx: &mut TxContext) {
        mysticon.training_status = false; // Suspends the Mysticon's training status.
    }

    // Creates a new QuestPass for a Mysticon, enabling its return to the game's ecosystem.
    // The QuestPass facilitates the Mysticon's movement between a player's custodial and non-custodial wallets.
    // It is issued by the game admin and ties a Mysticon with the player's wallets, preparing it for re-import.
    public fun new_quest_pass(_: &mut AdminCap, mysticon_id: ID, custodial_wallet: address, ctx: &mut TxContext
    ): QuestPass {
        QuestPass {
            id: object::new(ctx), // Generates a unique identifier for the QuestPass.
            mysticon_id, // Associates the QuestPass with a specific Mysticon.
            custodial_wallet, // Links the custodial wallet managed by the game.
        }
    }

    // Imports a Mysticon back into the game's ecosystem using a QuestPass.
    // This function reactivates the Mysticon's training status and transfers it to the game's custodial wallet,
    // allowing the player to continue engaging with the game using the Mysticon.
    public fun import_mysticon(quest_pass: QuestPass, mysticon: Mysticon, _ctx: &mut TxContext) {
        let QuestPass { id, mysticon_id, custodial_wallet } = quest_pass; // Unpack the QuestPass
        assert!(mysticon_id == object::id(&mysticon), EInvalidMysticon); // Validates the QuestPass.
        mysticon.training_status = true; // Reactivates the Mysticon's training status.
        transfer::public_transfer(mysticon, custodial_wallet); // Transfers the Mysticon to the custodial wallet.
        object::delete(id); // Deletes the used QuestPass.
    }

    public fun mysticon_uid_mut(self: &mut Mysticon): &mut UID {
        assert!(self.training_status, EMysticonIsExported);
        &mut self.id
    }

}