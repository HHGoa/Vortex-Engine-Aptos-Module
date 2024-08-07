module vortex_engine_addr::vortexengine {

    use aptos_framework::event;
    use std::string::String;
    #[test_only]
    use std::string;
    #[test_only]
    use std::debug;
    use aptos_std::table::{Self, Table};
    use std::signer;
    use aptos_framework::account;

    // Errors
    const E_NOT_INITIALIZED: u64 = 1;
    const ETASK_DOESNT_EXIST: u64 = 2;
    const ETASK_IS_COMPLETED: u64 = 3;

    struct EntityList has key {
        entries: Table<u64, EntryData>,
        set_entry_event: event::EventHandle<EntryData>,
        entry_counter: u64
    }
    
    struct EntryData has store, drop, copy {
        entry_id: u64,
        Walletaddress: address,
        ipfscontent: String,
        timestamp: String,
    }

    public entry fun create_list(account: &signer) {
        let entries_holder = EntityList {
            entries: table::new(),
            set_entry_event: account::new_event_handle<EntryData>(account),
            entry_counter: 0
        };
        move_to(account, entries_holder);
    }

    public entry fun create_entry(account: &signer, ipfscontent: String, timestamp: String) acquires EntityList {
        let signer_address = signer::address_of(account);

        assert!(exists<EntityList>(signer_address), E_NOT_INITIALIZED);

        let entity_list = borrow_global_mut<EntityList>(signer_address);

        // Increment the entry counter
        let counter = entity_list.entry_counter + 1;

        let new_entry = EntryData {
            entry_id: counter,
            Walletaddress: signer_address,
            ipfscontent,
            timestamp
        };

        // Update the table with the new entry
        table::upsert(&mut entity_list.entries, counter, new_entry);

        // Update the entry counter
        entity_list.entry_counter = counter;

        // Emit event for the new entry
        event::emit_event<EntryData>(
            &mut borrow_global_mut<EntityList>(signer::address_of(account)).set_entry_event,
            new_entry,
        );
    }

    #[test(admin = @0x123, admin2 = @0x456)]
    public entry fun test_flow(admin: signer, admin2: signer) acquires EntityList {
        // Create fresh accounts for testing
        account::create_account_for_test(signer::address_of(&admin));
        account::create_account_for_test(signer::address_of(&admin2));

        // Create lists for both admins
        create_list(&admin);
        create_list(&admin2);

        // Create entries for both admins with additional details for the first admin
        create_entry(&admin, string::utf8(b"ipfs_hash_admin1"), string::utf8(b"2024-08-05T12:00:00Z"));
        create_entry(&admin, string::utf8(b"ipfs_hash_admin2"), string::utf8(b"2024-08-06T12:00:00Z")); // Additional entry for admin1
        create_entry(&admin2, string::utf8(b"ipfs_hash_admin2"), string::utf8(b"2024-08-05T13:00:00Z"));

        // Verify entries for the first admin
        let entry_count_admin = event::counter(&borrow_global<EntityList>(signer::address_of(&admin)).set_entry_event);
        assert!(entry_count_admin == 2, 4); // Expecting 2 entries for admin1

        let entity_list_admin = borrow_global<EntityList>(signer::address_of(&admin));
        // debug::print(entity_list_admin);
        assert!(entity_list_admin.entry_counter == 2, 5); // Ensure entry counter is correct

        // Verify the first entry for admin1
        let entry_record_admin1 = table::borrow(&entity_list_admin.entries, 1);
        debug::print(entry_record_admin1);
        assert!(entry_record_admin1.entry_id == 1, 6);
        assert!(entry_record_admin1.ipfscontent == string::utf8(b"ipfs_hash_admin1"), 7);
        assert!(entry_record_admin1.timestamp == string::utf8(b"2024-08-05T12:00:00Z"), 8);
        assert!(entry_record_admin1.Walletaddress == signer::address_of(&admin), 9);

        // Verify the second entry for admin1
        let entry_record_admin2 = table::borrow(&entity_list_admin.entries, 2);
        debug::print(entry_record_admin2);
        assert!(entry_record_admin2.entry_id == 2, 10);
        assert!(entry_record_admin2.ipfscontent == string::utf8(b"ipfs_hash_admin2"), 11);
        assert!(entry_record_admin2.timestamp == string::utf8(b"2024-08-06T12:00:00Z"), 12);
        assert!(entry_record_admin2.Walletaddress == signer::address_of(&admin), 13);

        // Verify entries for the second admin
        let entry_count_admin2 = event::counter(&borrow_global<EntityList>(signer::address_of(&admin2)).set_entry_event);
        assert!(entry_count_admin2 == 1, 14); // Expecting 1 entry for admin2

        let entity_list_admin2 = borrow_global<EntityList>(signer::address_of(&admin2));
        // debug::print(entity_list_admin2);
        assert!(entity_list_admin2.entry_counter == 1, 15);

        let entry_record_admin2 = table::borrow(&entity_list_admin2.entries, 1);
        debug::print(entry_record_admin2);
        assert!(entry_record_admin2.entry_id == 1, 16);
        assert!(entry_record_admin2.ipfscontent == string::utf8(b"ipfs_hash_admin2"), 17);
        assert!(entry_record_admin2.timestamp == string::utf8(b"2024-08-05T13:00:00Z"), 18);
        assert!(entry_record_admin2.Walletaddress == signer::address_of(&admin2), 19);
    }


    #[test(admin = @0x123)]
    #[expected_failure(abort_code = E_NOT_INITIALIZED)]
    public entry fun account_can_not_update_entry(admin: signer) acquires EntityList {
        account::create_account_for_test(signer::address_of(&admin));
        create_entry(&admin, string::utf8(b"ipfs_hash"), string::utf8(b"2024-08-05T12:00:00Z"));
    }
}
