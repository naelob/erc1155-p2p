
%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_lt_felt
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_le, 
    uint256_eq,
    uint256_add,
    uint256_sub
)


from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from src.utils.token.erc1155.interfaces.IERC1155 import IERC1155

from src.utils.token.erc1155.library import ERC1155
from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.upgrades.library import Proxy

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from src.utils.token.erc1155.constants import (
    ON_ERC1155_RECEIVED_SELECTOR,
    ON_ERC1155_BATCH_RECEIVED_SELECTOR,
)

//
// STRUCTS
//

namespace TradeStatus {
    const Open = 1;
    const Executed = 2;
    const Cancelled = 3;
}

struct ResourcesNeeded {
    MIN_WOOD : Uint256,
    MIN_STONE : Uint256,
    MIN_COAL : Uint256,
    MIN_COPPER : Uint256,
    MIN_OBSIDIAN : Uint256,
    MIN_SILVER : Uint256,
    MIN_IRONWOOD : Uint256,
    MIN_COLD_IRON : Uint256,
    MIN_GOLD : Uint256,
    MIN_HARTWOOD : Uint256,
    MIN_DIAMONDS : Uint256,
    MIN_SAPPHIRE : Uint256,
    MIN_RUBY : Uint256,
    MIN_DEEP_CRYSTAL : Uint256,
    MIN_IGNUM : Uint256,
    MIN_ETHEREAL_SILICA : Uint256,
    MIN_TRUE_ICE : Uint256,
    MIN_TWILIGHT_QUARTZ : Uint256,
    MIN_ALCHEMICAL_SILVER : Uint256,
    MIN_ADAMANTINE : Uint256,
    MIN_MITHRAL : Uint256,
    MIN_DRAGONHIDE : Uint256,
}

struct Trade {
    owner : felt,
    asset_contract: felt,
    asset_ids_len : felt,
    asset_amounts_len : felt,
    status: felt,  // from TradeStatus
    needs : ResourcesNeeded,
    expiration : felt,
}

// 
// EVENTS
//

@event
func TradeOpened(trade: Trade) {
}

@event
func TradeCancelled(trade : Trade) {
}

@event
func TradeExecuted(trade : Trade, executor : felt) {
}

//
// Storage
// 

// Indexed list of all trades
@storage_var
func _trades(idx: felt) -> (trade : Trade) {
}

@storage_var
func _assets_ids_of_trades(idx : felt, j : felt) -> (id : Uint256) {
}

@storage_var
func _amounts_ids_of_trades(idx : felt, j : felt) -> (amount : Uint256) {
}


// The current number of trades
@storage_var
func trade_counter() -> (value: felt) {
}

// Address of the ERC1155 contract
@storage_var
func asset_address() -> (res: felt) {
}

//##############
// CONSTRUCTOR #
//##############

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin : felt,
    asset_token : felt
) {
    Proxy.initializer(proxy_admin);    
    Ownable.initializer(proxy_admin);
    asset_address.write(asset_token);
    trade_counter.write(1);
    return ();
}

//##################
// TRADE FUNCTIONS #
//##################

@external
func open_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token_ids_len : felt, 
    _token_ids: Uint256*, 
    _token_amounts_len : felt, 
    _token_amounts : Uint256*, 
    _resources_needed_len : felt,
    _resources_needed : Uint256*,
    _expiration : felt
) {
    alloc_locals;
    Pausable.assert_not_paused();

    assert _token_ids_len = _token_amounts_len;

    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();
    
    let (asset_add) = asset_address.read();

    // Make sure caller owns the ERC1155 assets
    _assert_ownership(_token_ids_len, _token_ids, _token_amounts_len, _token_amounts);

    // check if expiration is valid
    let (block_timestamp) = get_block_timestamp();
    with_attr error_message("P2P_Market : Expiration Is Not Valid") {
       assert_nn_le(block_timestamp, _expiration);
    }
    
    let (trade_count) = trade_counter.read();
    
    //assert owner_of = caller;

    let (local needs : ResourcesNeeded) = _get_needs(_resources_needed);
    local trade : Trade = Trade(
        caller,
        asset_add,
        _token_ids_len,
        _token_amounts_len,
        TradeStatus.Open,
        needs,
        _expiration
    );

    //_trades.write(trade_count, trade);

    // save assets/amounts ids for each trade 
    local start = 0;
    _write_assets_inside_storage{syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,start=start}(trade_count, _token_ids_len, _token_ids);
    local start_two = 0;
    _write_amounts_inside_storage{syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr,start=start_two}(trade_count, _token_amounts_len, _token_amounts);

    // increment
    trade_counter.write(trade_count + 1);

    TradeOpened.emit(trade);

    return ();
}

@external
func execute_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _trade_id : felt
) {
    alloc_locals;
    Pausable.assert_not_paused();

    let (caller) = get_caller_address();
    let (this_address) = get_contract_address();

    let (trade) = _trades.read(_trade_id);
        
    // address of ERC1155
    let (token_address) = asset_address.read();

    with_attr error_message("P2P_Market : Trade Not Opened") {
        assert trade.status = TradeStatus.Open;
    }

    with_attr error_message("P2P_Market : Expiration Issue") {
        assert_time_in_range(_trade_id);    
    }

    _check_if_party_owns_needs(trade.needs, caller);

    // get assets_ids and amounts for the trade
    let (local assets_ids: Uint256*) = alloc();
    local start = 0;
    let (local assets : Uint256*) = _get_assets_ids_storage{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=start
    }(_trade_id, trade.asset_ids_len, assets_ids);


    let (local amounts_ids: Uint256*) = alloc();
    local start_two = 0;
    let (local amounts : Uint256*) = _get_amounts_ids_storage{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=start_two
    }(_trade_id, trade.asset_amounts_len, amounts_ids);

    let (local null : felt*) = alloc();

    // transfer items to contract
    IERC1155.safeBatchTransferFrom(
        token_address, 
        trade.owner, 
        this_address, 
        trade.asset_ids_len,
        assets,
        trade.asset_amounts_len,
        amounts,
        0, 
        null
    );

    onERC1155BatchReceived(
        caller, 
        trade.owner,
        trade.asset_ids_len,
        assets,
        trade.asset_amounts_len,
        amounts,
        0, 
        null
    );

    // transfer items to buyer
    IERC1155.safeBatchTransferFrom(
        token_address, 
        this_address, 
        caller, 
        trade.asset_ids_len,
        assets,
        trade.asset_amounts_len,
        amounts,
        0, 
        null
    );

    let (local asset_ids_ : Uint256*) = alloc();
    local index_i : Uint256 = Uint256(1,0);
    let (local ids : Uint256*) = _asset_ids_loop{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=index_i
    }(asset_ids_);

    let (local asset_amounts : Uint256*) = alloc();
    let (local amounts_two : Uint256*) = _asset_amounts_loop(asset_amounts, trade.needs);

    // transfer buyer's goods (what the writer of the swap actually needs in exchange) to creator of swap
    IERC1155.safeBatchTransferFrom(
        token_address, 
        caller, 
        trade.owner, 
        22,
        ids,
        22,
        amounts_two,
        0, 
        null
    );

    local trade_executed : Trade = Trade(
        trade.owner,
        trade.asset_contract,
        trade.asset_ids_len,
        trade.asset_amounts_len,
        TradeStatus.Executed,
        trade.needs,
        trade.expiration
    );
    _trades.write(_trade_id, trade_executed);

    TradeExecuted.emit(trade_executed, caller);

    return ();
}

@external
func cancel_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _trade_id: felt
) {
    alloc_locals;
    // TODO : add owner check
    Pausable.assert_not_paused();
    let (trade) = _trades.read(_trade_id);

    with_attr error_message("P2P_Market : Trade Not Opened") {
        assert trade.status = TradeStatus.Open;
    }

    with_attr error_message("P2P_Market : Expiration Issue") {
        assert_time_in_range(_trade_id);    
    }

    local cancelled_trade : Trade = Trade(
        trade.owner,
        trade.asset_contract,
        trade.asset_ids_len,
        trade.asset_amounts_len,
        TradeStatus.Cancelled,
        trade.needs,
        trade.expiration
    );
    _trades.write(_trade_id, cancelled_trade);

    TradeCancelled.emit(cancelled_trade);
    return ();
}

@external
func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, from_: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
    return (selector=ON_ERC1155_RECEIVED_SELECTOR);
}

@external
func onERC1155BatchReceived(
    operator: felt,
    from_: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt,
    data: felt*,
) -> (selector: felt) { 
    return (selector=ON_ERC1155_BATCH_RECEIVED_SELECTOR);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interface_id: felt
) -> (success: felt) {
    return ERC165.supports_interface(interface_id);
} 

////
// MODIFIERS
///

func assert_time_in_range{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _trade_id : felt
) {
    let (block_timestamp) = get_block_timestamp();
    let (trade) = _trades.read(_trade_id);
    // check trade within
    assert_nn_le(block_timestamp, trade.expiration);

    return ();
}


func _uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    assert_lt_felt(value.high, 2 ** 123);
    return (value.high * (2 ** 128) + value.low,);
}


//##########
// GETTERS #
//##########

@view
func get_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    idx: felt
) -> (
    trade: Trade
) {
    return _trades.read(idx);
}

@view
func get_trade_counter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: felt
) {
    return trade_counter.read();
}

// Returns a trades status
@view
func get_trade_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    idx: felt
) -> (status: felt) {
    let (trade) = _trades.read(idx);
    return (status=trade.status);
}

@view
func paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    paused: felt
) {
    let (paused) = Pausable.is_paused();
    return (paused=paused);
}

@view
func get_asset_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (res : felt) {
    let (res) = asset_address.read();
    return (res=res);
}

//
// SETTERS 
//

@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._pause();
    return ();
}

@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._unpause();
    return ();
}

//// 
//// INTERNAL
///


// Internal
func _write_assets_inside_storage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, start : felt}(
    trade_count : felt, _token_ids_len : felt, _token_ids : Uint256*
) {
    alloc_locals;
    if (_token_ids_len == 0) {
        return ();
    }
    _assets_ids_of_trades.write(trade_count, start, [_token_ids]);

    local new_start = start + 1;
    return _write_assets_inside_storage{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=new_start
    }(trade_count=trade_count, _token_ids_len=_token_ids_len - 1, _token_ids=_token_ids + Uint256.SIZE);
}

func _write_amounts_inside_storage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, start : felt}(
    trade_count : felt, _token_amounts_len : felt, _token_amounts : Uint256*
) {
    alloc_locals;
    if (_token_amounts_len == 0) {
        return ();
    }
    _amounts_ids_of_trades.write(trade_count, start, [_token_amounts]);

    local new_start = start + 1;
    return _write_amounts_inside_storage{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=new_start
    }(trade_count=trade_count, _token_amounts_len=_token_amounts_len - 1, _token_amounts=_token_amounts + Uint256.SIZE);
}

func _get_assets_ids_storage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, start : felt}(
    _trade_id : felt, asset_ids_len : felt, assets_ids : Uint256*
) -> (assets : Uint256*){
    alloc_locals;
    
    if (asset_ids_len == 0) {
        return (assets=assets_ids);
    }
    
    let (id : Uint256) = _assets_ids_of_trades.read(_trade_id, start);
    assert [assets_ids] = id;

    local new_start = start + 1;
    return _get_assets_ids_storage{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=new_start
    }(_trade_id=_trade_id, asset_ids_len=asset_ids_len - 1, assets_ids=assets_ids + Uint256.SIZE);   
}  


func _get_amounts_ids_storage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, start : felt}(
    _trade_id : felt, amounts_ids_len : felt, amounts_ids : Uint256*
) -> (amounts : Uint256*){
    alloc_locals;
    
    if (amounts_ids_len == 0) {
        return (amounts=amounts_ids);
    }
    
    let (amount : Uint256) = _amounts_ids_of_trades.read(_trade_id, start);
    assert [amounts_ids] = amount;

    local new_start = start + 1;
    return _get_amounts_ids_storage{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=new_start
    }(_trade_id=_trade_id, amounts_ids_len=amounts_ids_len - 1, amounts_ids=amounts_ids+ Uint256.SIZE);   
}  

// convert an array of min_resources to a struct
func _get_needs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _resources_needed : Uint256*
) -> (needs : ResourcesNeeded){  
    alloc_locals;

    local res : ResourcesNeeded = ResourcesNeeded(
        [_resources_needed],
        [_resources_needed + Uint256.SIZE],
        [_resources_needed + 2 * Uint256.SIZE],
        [_resources_needed + 3 * Uint256.SIZE],
        [_resources_needed + 4 * Uint256.SIZE],
        [_resources_needed + 5 * Uint256.SIZE],
        [_resources_needed + 6 * Uint256.SIZE],
        [_resources_needed + 7 * Uint256.SIZE],
        [_resources_needed + 8 * Uint256.SIZE],
        [_resources_needed + 9 * Uint256.SIZE],
        [_resources_needed + 10 * Uint256.SIZE],
        [_resources_needed + 11 * Uint256.SIZE],
        [_resources_needed + 12 * Uint256.SIZE],
        [_resources_needed + 13 * Uint256.SIZE],
        [_resources_needed + 14 * Uint256.SIZE],
        [_resources_needed + 15 * Uint256.SIZE],
        [_resources_needed + 16 * Uint256.SIZE],
        [_resources_needed + 17 * Uint256.SIZE],
        [_resources_needed + 18 * Uint256.SIZE],
        [_resources_needed + 19 * Uint256.SIZE],
        [_resources_needed + 20 * Uint256.SIZE],
        [_resources_needed + 21 * Uint256.SIZE],
    );
    return (needs=res);
}

func _assert_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token_ids_len : felt, _token_ids : Uint256*, _token_amounts_len : felt, _token_amounts : Uint256*
) { 
    alloc_locals;
    // ERC1155 contract address
    let (token_address) = asset_address.read();
    let (caller) = get_caller_address();

    let (local owners : felt*) = alloc();
    assert [owners] = caller;
    let (balance_len : felt, balance : Uint256*) = IERC1155.balanceOfBatch(token_address, 1, owners, _token_ids_len, _token_ids);
    _assert_amounts(start=0, amounts=_token_amounts, balance=balance);
    return ();
}
 
func _check_if_party_owns_needs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    needs : ResourcesNeeded, caller : felt
){
    alloc_locals;
    // ERC1155 contract address
    let (token_address) = asset_address.read();

    let (local asset_amounts : Uint256*) = alloc();
    let (local amounts : Uint256*) = _asset_amounts_loop(asset_amounts, needs);

    let (local asset_ids_ : Uint256*) = alloc();
    local index_i : Uint256 = Uint256(1,0);
    let (local ids : Uint256*) = _asset_ids_loop{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=index_i
    }(asset_ids_);

    let (local owners : felt*) = alloc();
    assert [owners] = caller;
    
    let (balance_len : felt, balance : Uint256*) = IERC1155.balanceOfBatch(token_address, 1, owners, 22, ids);

    _assert_amounts(start=0, amounts=amounts, balance=balance);
    return ();
}

// Check if opposite Party owns at least the MIN_Resources wanted by the initial writer of the swap
func _assert_amounts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    start : felt, amounts : Uint256*, balance : Uint256*
) { 
    if (start == 22) {
        return ();
    }
    with_attr error_message("P2P_Market : Error Inside Asserting Needs Amounts") {
        uint256_le([amounts], [balance]);
    }
    return _assert_amounts(start=start+1, amounts=amounts + Uint256.SIZE, balance=balance + Uint256.SIZE);
}

// returns an array [1....22]
func _asset_ids_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, start : Uint256}(
    assets_ids : Uint256*
) -> (res : Uint256*){
    alloc_locals;
    let (bool) = uint256_eq(start, Uint256(23,0));
    if (bool == 1) {
        return (res=assets_ids);
    }
    assert [assets_ids] = start;
    let (local new_start : Uint256, _) = uint256_add(start, Uint256(1,0));
    return _asset_ids_loop{
        syscall_ptr=syscall_ptr, pedersen_ptr=pedersen_ptr, range_check_ptr=range_check_ptr, start=new_start
    }(assets_ids=assets_ids + Uint256.SIZE);
}

// returns an array with the amounts matching the struct ResourceNeeded
func _asset_amounts_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    assets_amounts : Uint256*, needs : ResourcesNeeded
) -> (res : Uint256*){
  
    assert [assets_amounts] = needs.MIN_WOOD;
    assert [assets_amounts + 1 * Uint256.SIZE] = needs.MIN_STONE;
    assert [assets_amounts + 2 * Uint256.SIZE] = needs.MIN_COAL;
    assert [assets_amounts + 3 * Uint256.SIZE] = needs.MIN_COPPER;
    assert [assets_amounts + 4 * Uint256.SIZE] = needs.MIN_OBSIDIAN;
    assert [assets_amounts + 5 * Uint256.SIZE] = needs.MIN_IRONWOOD;
    assert [assets_amounts + 6 * Uint256.SIZE] = needs.MIN_COLD_IRON;
    assert [assets_amounts + 7 * Uint256.SIZE] = needs.MIN_GOLD;
    assert [assets_amounts + 8 * Uint256.SIZE] = needs.MIN_HARTWOOD;
    assert [assets_amounts + 9 * Uint256.SIZE] = needs.MIN_DIAMONDS;
    assert [assets_amounts + 10 * Uint256.SIZE] = needs.MIN_SAPPHIRE;
    assert [assets_amounts + 11 * Uint256.SIZE] = needs.MIN_RUBY; 
    assert [assets_amounts + 12 * Uint256.SIZE] = needs.MIN_DEEP_CRYSTAL; 
    assert [assets_amounts + 13 * Uint256.SIZE] = needs.MIN_IGNUM;
    assert [assets_amounts + 14 * Uint256.SIZE] = needs.MIN_ETHEREAL_SILICA;
    assert [assets_amounts + 15 * Uint256.SIZE] = needs.MIN_TRUE_ICE;
    assert [assets_amounts + 16 * Uint256.SIZE] = needs.MIN_TWILIGHT_QUARTZ;
    assert [assets_amounts + 17 * Uint256.SIZE] = needs.MIN_ALCHEMICAL_SILVER;
    assert [assets_amounts + 18 * Uint256.SIZE] = needs.MIN_ADAMANTINE;
    assert [assets_amounts + 19 * Uint256.SIZE] = needs.MIN_MITHRAL;
    assert [assets_amounts + 20 * Uint256.SIZE] = needs.MIN_DRAGONHIDE;
    
    return (res=assets_amounts);
}

