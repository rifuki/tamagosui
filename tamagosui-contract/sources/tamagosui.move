module 0x0::tamagosui;

use std::string::{Self, String};
use sui::{clock::Clock, display, dynamic_field, event, package};

// === Errors ===
const E_NOT_ENOUGH_COINS: u64 = 101;
const E_PET_NOT_HUNGRY: u64 = 102;
const E_PET_TOO_TIRED: u64 = 103;
const E_PET_TOO_HUNGRY: u64 = 104;
const E_ITEM_ALREADY_EQUIPPED: u64 = 105;
const E_NO_ITEM_EQUIPPED: u64 = 106;
const E_NOT_ENOUGH_EXP: u64 = 107;
const E_PET_IS_ASLEEP: u64 = 108;
const E_PET_IS_ALREADY_ASLEEP: u64 = 109;

// === Constants ===
const PET_LEVEL_1_IMAGE_URL: vector<u8> = b"https://raw.githubusercontent.com/xfajarr/stacklend/refs/heads/main/photo_2023-04-30_12-46-11.jpg";
const PET_LEVEL_1_IMAGE_WITH_GLASSES_URL: vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreibizappmcjaq5a5metl27yc46co4kxewigq6zu22vovwvn5qfsbiu";
const PET_LEVEL_2_IMAGE_URL: vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreia5tgsowzfu6mzjfcxagfpbkghfuho6y5ybetxh3wabwrc5ajmlpq";
const PET_LEVEL_2_IMAGE_WITH_GLASSES_URL:vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreif5bkpnqyybq3aqgafqm72x4wfjwcuxk33vvykx44weqzuilop424";
const PET_LEVEL_3_IMAGE_URL: vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreidnqerfwxuxkrdsztgflmg5jwuespdkrazl6qmk7ykfgmrfzvinoy";
const PET_LEVEL_3_IMAGE_WITH_GLASSES_URL:vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreigs6r3rdupoji7pqmpwe76z7wysguzdlq43t3wqmzi2654ux5n6uu";
const PET_SLEEP_IMAGE_URL: vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreihwofl5stihtzjixfhrtznd7zqkclfhmlshgsg7cbszzjqqpvf7ae";
const ACCESSORY_GLASSES_IMAGE_URL: vector<u8> = b"https://tan-kind-lizard-741.mypinata.cloud/ipfs/bafkreigyivmq45od3jkryryi3w6t5j65hcnfh5kgwpi2ex7llf2i6se7de";

const EQUIPPED_ITEM_KEY: vector<u8> = b"equipped_item";
const SLEEP_STARTED_AT_KEY: vector<u8> = b"sleep_started_at";

// === Game Balance ===
public struct GameBalance has copy, drop {
    max_stat: u8,
    
    // Feed settings
    feed_coins_cost: u64,
    feed_experience_gain: u64,
    feed_hunger_gain: u8,
    
    // Play settings
    play_energy_loss: u8,
    play_hunger_loss: u8,
    play_experience_gain: u64,
    play_happiness_gain: u8,
    
    // Work settings
    work_energy_loss: u8,
    work_happiness_loss: u8,
    work_hunger_loss: u8,
    work_coins_gain: u64,
    work_experience_gain: u64,
    
    // Sleep settings (in milliseconds)
    sleep_energy_gain_ms: u64,
    sleep_happiness_loss_ms: u64,
    sleep_hunger_loss_ms: u64,

    // Level settings
    exp_per_level: u64,
}

fun get_game_balance(): GameBalance {
    GameBalance {
        max_stat: 100,
        
        // Feed
        feed_coins_cost: 5,
        feed_experience_gain: 5,
        feed_hunger_gain: 20,
        
        // Play
        play_energy_loss: 15,
        play_hunger_loss: 15,
        play_experience_gain: 10,
        play_happiness_gain: 25,
        
        // Work
        work_energy_loss: 20,
        work_hunger_loss: 20,
        work_happiness_loss: 20,
        work_coins_gain: 10,
        work_experience_gain: 15,

        // Sleep (rates per millisecond)
        sleep_energy_gain_ms: 1000,    // 1 energy per second
        sleep_happiness_loss_ms: 700, // 1 happiness loss per 0.7 seconds
        sleep_hunger_loss_ms: 500,    // 1 hunger loss per 0.5 seconds
        
        // Level
        exp_per_level: 100,
    }
}

public struct TAMAGOSUI has drop {}

public struct Pet has key, store {
    id: UID,
    name: String,
    image_url: String,
    adopted_at: u64,
    stats: PetStats,
    game_data: PetGameData,
}

public struct PetAccessory has key, store {
    id: UID,
    name: String,
    image_url: String
}

public struct PetStats has store {
    energy: u8,
    happiness: u8,
    hunger: u8,
}

public struct PetGameData has store {
    coins: u64,
    experience: u64,
    level: u8,
}

// === Events ===

public struct PetAdopted has copy, drop {
    pet_id: ID,
    name: String,
    adopted_at: u64
}
public struct PetAction has copy, drop {
    pet_id: ID,
    action: String,
    energy: u8,
    happiness: u8,
    hunger: u8
}

fun init(witness: TAMAGOSUI, ctx: &mut TxContext) {
    let publisher = package::claim(witness, ctx);

    let pet_keys = vector[
        string::utf8(b"name"),
        string::utf8(b"image_url"),
        string::utf8(b"birth_date"),
        string::utf8(b"experience"),
        string::utf8(b"level"),
    ];

    let pet_values = vector[
        string::utf8(b"{name}"),
        string::utf8(b"{image_url}"),
        string::utf8(b"{adopted_at}"),
        string::utf8(b"{game_data.experience}"),
        string::utf8(b"{game_data.level}"),
    ];

    let mut pet_display = display::new_with_fields<Pet>(&publisher, pet_keys, pet_values, ctx);
    pet_display.update_version();
    transfer::public_transfer(pet_display, ctx.sender());

    let accessory_keys = vector[
        string::utf8(b"name"),
        string::utf8(b"image_url")
    ];
    let accessory_values = vector[
        string::utf8(b"{name}"),
        string::utf8(b"{image_url}")
    ];
    let mut accessory_display = display::new_with_fields<PetAccessory>(&publisher, accessory_keys, accessory_values, ctx);
    accessory_display.update_version();
    transfer::public_transfer(accessory_display, ctx.sender());

    transfer::public_transfer(publisher, ctx.sender());
}

public entry fun adopt_pet(
    name: String,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let current_time = clock.timestamp_ms();

    let pet_stats = PetStats {
        energy: 60,
        happiness: 50,
        hunger: 40,
    };

    let pet_game_data = PetGameData {
        coins: 20,
        experience: 0,
        level: 1
    };

    let pet = Pet {
        id: object::new(ctx),
        name,
        image_url: string::utf8(PET_LEVEL_1_IMAGE_URL),
        adopted_at: current_time,
        stats: pet_stats,
        game_data: pet_game_data
    };

    let pet_id = object::id(&pet);

    event::emit(PetAdopted {
        pet_id: pet_id,
        name: pet.name,
        adopted_at: pet.adopted_at
    });

    transfer::public_transfer(pet, ctx.sender());
}

public entry fun feed_pet(pet: &mut Pet) {
    assert!(!is_sleeping(pet), E_PET_IS_ASLEEP);

    let gb = get_game_balance();

    assert!(pet.stats.hunger < gb.max_stat, E_PET_NOT_HUNGRY);
    assert!(pet.game_data.coins >= gb.feed_coins_cost, E_NOT_ENOUGH_COINS);

    pet.game_data.coins = pet.game_data.coins - gb.feed_coins_cost;
    pet.game_data.experience = pet.game_data.experience + gb.feed_experience_gain;
    pet.stats.hunger = if (pet.stats.hunger + gb.feed_hunger_gain > gb.max_stat)
        gb.max_stat 
    else 
        pet.stats.hunger + gb.feed_hunger_gain;

    emit_action(pet, b"fed");
}

public entry fun play_with_pet(pet: &mut Pet) {
    assert!(!is_sleeping(pet), E_PET_IS_ASLEEP);

    let gb = get_game_balance();
    assert!(pet.stats.energy >= gb.play_energy_loss, E_PET_TOO_TIRED);
    assert!(pet.stats.hunger >= gb.play_hunger_loss, E_PET_TOO_HUNGRY);

    pet.stats.energy = pet.stats.energy - gb.play_energy_loss;
    pet.stats.hunger = pet.stats.hunger - gb.play_hunger_loss;
    pet.game_data.experience = pet.game_data.experience + gb.play_experience_gain;
    pet.stats.happiness = if (pet.stats.happiness + gb.play_happiness_gain > gb.max_stat) 
        gb.max_stat 
    else 
        pet.stats.happiness + gb.play_happiness_gain;

    emit_action(pet, b"played");
}

public entry fun work_for_coins(pet: &mut Pet) {
    assert!(!is_sleeping(pet), E_PET_IS_ASLEEP);

    let gb = get_game_balance();

    assert!(pet.stats.energy >= gb.work_energy_loss, E_PET_TOO_TIRED);
    assert!(pet.stats.happiness >= gb.work_happiness_loss, E_PET_NOT_HUNGRY);
    assert!(pet.stats.hunger >= gb.work_hunger_loss, E_PET_TOO_HUNGRY);
    
    pet.stats.energy = if (pet.stats.energy >= gb.work_energy_loss)
        pet.stats.energy - gb.work_energy_loss
    else 
        0;
    pet.stats.happiness = if (pet.stats.happiness >= gb.work_happiness_loss)
        pet.stats.happiness - gb.work_happiness_loss
    else 
        0;
    pet.stats.hunger = if (pet.stats.hunger >= gb.work_hunger_loss)
        pet.stats.hunger - gb.work_hunger_loss
    else 
        0;
    pet.game_data.coins = pet.game_data.coins + gb.work_coins_gain;
    pet.game_data.experience = pet.game_data.experience + gb.work_experience_gain;

    emit_action(pet, b"worked");
}

public entry fun let_pet_sleep(pet: &mut Pet, clock: &Clock) {
    assert!(!is_sleeping(pet), E_PET_IS_ALREADY_ASLEEP);

    let key = string::utf8(SLEEP_STARTED_AT_KEY);
    dynamic_field::add(&mut pet.id, key, clock.timestamp_ms());

    pet.image_url = string::utf8(PET_SLEEP_IMAGE_URL);

    emit_action(pet, b"started_sleeping");
}

public entry fun wake_up_pet(pet: &mut Pet, clock: &Clock) {
    assert!(is_sleeping(pet), E_PET_IS_ASLEEP);
    
    let key = string::utf8(SLEEP_STARTED_AT_KEY);
    let sleep_started_at: u64 = dynamic_field::remove<String, u64>(&mut pet.id, key);
    let duration_ms = clock.timestamp_ms() - sleep_started_at;

    let gb = get_game_balance();

    // Calculate energy gained
    let energy_gained_u64 = duration_ms / gb.sleep_energy_gain_ms;
    // Cap energy gain to max_stat
    let energy_gained = if (energy_gained_u64 > (gb.max_stat as u64)) {
        gb.max_stat 
    } else {
        (energy_gained_u64 as u8)
    };
    pet.stats.energy = if (pet.stats.energy + energy_gained > gb.max_stat) gb.max_stat else pet.stats.energy + energy_gained;

    // Calculate happiness lost
    let happiness_lost_u64 = duration_ms / gb.sleep_happiness_loss_ms;
    let happiness_lost = if (happiness_lost_u64 > (gb.max_stat as u64)) {
        gb.max_stat
    } else {
        (happiness_lost_u64 as u8)
    };
    pet.stats.happiness = if (pet.stats.happiness > happiness_lost) pet.stats.happiness - happiness_lost else 0;

    // Calculate hunger lost
    let hunger_lost_u64 = duration_ms / gb.sleep_hunger_loss_ms;
    let hunger_lost = if (hunger_lost_u64 > (gb.max_stat as u64)) {
        gb.max_stat
    } else {
        (hunger_lost_u64 as u8)
    };
    pet.stats.hunger = if (pet.stats.hunger > hunger_lost) pet.stats.hunger - hunger_lost else 0;

    update_pet_image(pet);

    emit_action(pet, b"woke_up");
}


public entry fun check_and_level_up(pet: &mut Pet) {
    assert!(!is_sleeping(pet), E_PET_IS_ASLEEP);

    let gb = get_game_balance();

    // Calculate required exp: level * exp_per_level
    let required_exp = (pet.game_data.level as u64) * gb.exp_per_level;
    assert!(pet.game_data.experience >= required_exp, E_NOT_ENOUGH_EXP);

    // Level up
    pet.game_data.level = pet.game_data.level + 1;
    pet.game_data.experience = pet.game_data.experience - required_exp;
    
    // Update image based on level and equipped accessory
    update_pet_image(pet);

    emit_action(pet, b"leveled_up")
}

public entry fun mint_accessory(ctx: &mut TxContext) {
    let accessory = PetAccessory {
        id: object::new(ctx),
        name: string::utf8(b"cool glasses"),
        image_url: string::utf8(ACCESSORY_GLASSES_IMAGE_URL)
    };
    transfer::public_transfer(accessory, ctx.sender());
}

public entry fun equip_accessory(pet: &mut Pet, accessory: PetAccessory) {
    assert!(!is_sleeping(pet), E_PET_IS_ASLEEP);

    let key = string::utf8(EQUIPPED_ITEM_KEY);
    assert!(!dynamic_field::exists_<String>(&pet.id, copy key), E_ITEM_ALREADY_EQUIPPED);

    // Add accessory to pet
    dynamic_field::add(&mut pet.id, key, accessory);
    // Update image
    update_pet_image(pet);
    emit_action(pet, b"equipped_item");
}

public entry fun unequip_accessory(pet: &mut Pet, ctx: &mut TxContext) {
    assert!(!is_sleeping(pet), E_PET_IS_ASLEEP);

    let key = string::utf8(EQUIPPED_ITEM_KEY);
    assert!(dynamic_field::exists_<String>(&pet.id, key), E_NO_ITEM_EQUIPPED);

    // Remove accessory
    let accessory: PetAccessory = dynamic_field::remove<String, PetAccessory>(&mut pet.id, key);
    // Update image
    update_pet_image(pet);

    transfer::transfer(accessory, ctx.sender());
    emit_action(pet, b"unequipped_item");
}

// === Helper Functions ===
fun emit_action(pet: &Pet, action: vector<u8>) {
    event::emit(PetAction {
        pet_id: object::id(pet),
        action: string::utf8(action),
        energy: pet.stats.energy,
        happiness: pet.stats.happiness,
        hunger: pet.stats.hunger,
    });
}

fun update_pet_image(pet: &mut Pet) {
    let key = string::utf8(EQUIPPED_ITEM_KEY);
    let has_accessory = dynamic_field::exists_<String>(&pet.id, key);
    
    if (pet.game_data.level == 1) {
        if (has_accessory) {
            pet.image_url = string::utf8(PET_LEVEL_1_IMAGE_WITH_GLASSES_URL);
        } else {
            pet.image_url = string::utf8(PET_LEVEL_1_IMAGE_URL);
        }
    } else if (pet.game_data.level == 2) {
        if (has_accessory) {
            pet.image_url = string::utf8(PET_LEVEL_2_IMAGE_WITH_GLASSES_URL);
        } else {
            pet.image_url = string::utf8(PET_LEVEL_2_IMAGE_URL);
        }
    } else if (pet.game_data.level >= 3) {
        if (has_accessory) {
            pet.image_url = string::utf8(PET_LEVEL_3_IMAGE_WITH_GLASSES_URL);
        } else {
            pet.image_url = string::utf8(PET_LEVEL_3_IMAGE_URL);
        }
    };
}

// === View Functions ===
public fun get_pet_name(pet: &Pet): String { pet.name }
public fun get_pet_adopted_at(pet: &Pet): u64 { pet.adopted_at }
public fun get_pet_coins(pet: &Pet): u64 { pet.game_data.coins }
public fun get_pet_experience(pet: &Pet): u64 { pet.game_data.experience }
public fun get_pet_level(pet: &Pet): u8 { pet.game_data.level }
public fun get_pet_energy(pet: &Pet): u8 { pet.stats.energy }
public fun get_pet_hunger(pet: &Pet): u8 { pet.stats.hunger }
public fun get_pet_happiness(pet: &Pet): u8 { pet.stats.happiness }

public fun get_pet_stats(pet: &Pet): (u8, u8, u8) {
    (pet.stats.energy, pet.stats.hunger, pet.stats.happiness)
}
public fun get_pet_game_data(pet: &Pet): (u64, u64, u8) {
    (pet.game_data.coins, pet.game_data.experience, pet.game_data.level)
}

public fun is_sleeping(pet: &Pet): bool {
    let key = string::utf8(SLEEP_STARTED_AT_KEY);
    dynamic_field::exists_<String>(&pet.id, key)
}

// === Test-Only Functions ===
#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(TAMAGOSUI {}, ctx);
}
