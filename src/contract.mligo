module C = struct
  // types
  type contract_metadata_type = (string, bytes)big_map

  type storage_type = {
    state: int;
    admin: address;
    locked: bool;
    metadata: contract_metadata_type
  }

  type return_type = operation list * storage_type

  // actions
  let assert_admin_or_not_locked (store: storage_type) : unit =
    let sender = Tezos.get_sender() in
    Assert.Error.assert ((not store.locked) || sender = store.admin) "not admin"

  let assert_admin (store: storage_type): unit =
    let sender = Tezos.get_sender() in
    Assert.Error.assert (sender = store.admin) "not admin"

  // entrypoints
  [@entry] let decrement (n: int) (store: storage_type): return_type = 
    let _assert = assert_admin_or_not_locked(store) in
    [], { store with state = store.state - n }

  [@entry] let increment (n: int) (store: storage_type): return_type = 
    let _assert = assert_admin_or_not_locked(store) in
    [], { store with state = store.state + n }

  [@entry] let set_lock (lockState: bool) (store: storage_type): return_type = 
    let _assert = assert_admin(store) in
    [], { store with locked = lockState }

// right now breaks tests
//  [@entry] let default (_: unit) (store: storage_type): return_type = [], store

  [@view] let get_lock_state(_params: unit) (store: storage_type): bool =
    store.locked
  let get_lock_state_off_chain_view(params: unit) (store: storage_type): bool = get_lock_state params store

  [@view] let get_state (_params: unit) (store: storage_type): int =
    store.state
  let get_state_off_chain_view(params: unit) (store: storage_type): int = get_state params store


  let generate_initial_storage(admin, about: address * bytes): storage_type = 
    let metadata = (Big_map.empty: contract_metadata_type) in
    let metadata: contract_metadata_type = Big_map.update ("") (Some(Bytes.pack("tezos-storage:content"))) metadata in
    let metadata = Big_map.update ("content") (Some(about)) metadata in
    { state = 0; admin = admin; locked = true; metadata = metadata }
end