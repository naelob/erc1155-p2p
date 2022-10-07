%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from src.p2p_resources_market.interfaces.IP2PMarket import IP2PMarket
from src.p2p_resources_market.interfaces.IAssetErc1155 import IAssetErc1155

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from src.p2p_resources_market.p2p_market import (
    Trade,
    ResourcesNeeded,
    TradeStatus
)

@external
func __setup__() {
    tempvar deployer_address = 123456789987654321;
    %{ 
        context.deployer_address = ids.deployer_address
        context.erc1155_address = deploy_contract("./src/p2p_resources_market/asset_erc1155.cairo").contract_address 
        context.p2p_market = deploy_contract("./src/p2p_resources_market/p2p_market.cairo", [context.deployer_address, context.erc1155_address]).contract_address 
    %}
    return ();
}

@external 
func test_open_contract{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    
    //%{ stop_prank_callable = start_prank(123) %}

    local contract_address : felt;
    local erc1155_address : felt;
    local caller : felt ;
    //assert caller = 0;
    %{ 
        ids.erc1155_address = context.erc1155_address
        ids.contract_address = context.p2p_market
        ids.caller = context.deployer_address
    %}


    let (res) = IP2PMarket.get_asset_address(contract_address=contract_address);
    assert res = erc1155_address;

    let (counter) = IP2PMarket.get_trade_counter(contract_address=contract_address);
    assert counter = 1;

    // Mint batch a set of ids
    let (local token_ids : Uint256*) = alloc(); 
    assert [token_ids] = Uint256(1,0);
    assert [token_ids + Uint256.SIZE] = Uint256(2,0);
    assert [token_ids + 2 * Uint256.SIZE] = Uint256(3,0);

    let (local token_amounts : Uint256*) = alloc(); 
    assert [token_amounts] = Uint256(1,0);
    assert [token_amounts + Uint256.SIZE] = Uint256(1,0);
    assert [token_amounts + 2 * Uint256.SIZE] = Uint256(1,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=caller,
        ids_len=3,
        ids=token_ids,
        amounts_len=3,
        amounts=token_amounts,
        data_len=0,
        data=null,
    );

    let (local balance_1 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(1,0));
    assert balance_1.low = 1;
    assert balance_1.high = 0;

    let (local balance_2 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(2,0));
    assert balance_2.low = 1;
    assert balance_2.high = 0;

    let (local balance_3 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(3,0));
    assert balance_3.low = 1;
    assert balance_3.high = 0;

    let (local resources_arr : Uint256*) = alloc(); 
    assert  [resources_arr] = Uint256(50,0);
    assert  [resources_arr + Uint256.SIZE] = Uint256(210,0);
    assert  [resources_arr + 2 * Uint256.SIZE] = Uint256(80,0);
    assert  [resources_arr + 3 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 4 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 5 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 6 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 7 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 8 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 9 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 10 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 11 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 12 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 13 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 14 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 15 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 16 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 17 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 18 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 19 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 20 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 21 * Uint256.SIZE] = Uint256(0,0);

    %{ stop_prank = start_prank(context.deployer_address,ids.contract_address) %}

    // Open Trade 
    IP2PMarket.open_trade( 
        contract_address=contract_address,
        _token_ids_len=3, 
        _token_ids=token_ids, 
        _token_amounts_len=3, 
        _token_amounts=token_amounts, 
        _resources_needed_len=22,
        _resources_needed=resources_arr,
        _expiration=172800,
    );
    %{ stop_prank() %}

    // check new trade inserted

    let (trade : Trade) = IP2PMarket.get_trade(contract_address=contract_address, idx=counter);
    assert trade.owner = 0;
    assert trade.asset_contract = res;
    assert trade.asset_ids_len = 3;
    assert trade.asset_amounts_len = 3;
    assert trade.status = TradeStatus.Open; 
    assert trade.expiration = 172800;

    // check resources 

    let needs : ResourcesNeeded = trade.needs;
    assert needs.MIN_WOOD.low = 50;
    assert needs.MIN_WOOD.high = 0;
    assert needs.MIN_STONE.low = 210;
    assert needs.MIN_STONE.high = 0;
    assert needs.MIN_COAL.low = 80;
    assert needs.MIN_COAL.high = 0;

    // check new counter
    let (new_counter) = IP2PMarket.get_trade_counter(contract_address=contract_address);
    assert new_counter = 2;


    return ();
}

@external
func test_cancel_trade{syscall_ptr: felt*, range_check_ptr}(
){
    alloc_locals;
    local p2p_contract_address;
    local erc1155_address;
    local caller;
    %{
        ids.p2p_contract_address = context.p2p_market
        ids.erc1155_address = context.erc1155_address
        ids.caller = context.deployer_address
    %}
    let (counter) = IP2PMarket.get_trade_counter(contract_address=p2p_contract_address);
    assert counter = 1;

    // OPEN A TRADE FIRST 
    // Mint batch a set of ids
    let (local token_ids : Uint256*) = alloc(); 
    assert [token_ids] = Uint256(1,0);
    assert [token_ids + Uint256.SIZE] = Uint256(2,0);
    assert [token_ids + 2 * Uint256.SIZE] = Uint256(3,0);

    let (local token_amounts : Uint256*) = alloc(); 
    assert [token_amounts] = Uint256(1,0);
    assert [token_amounts + Uint256.SIZE] = Uint256(1,0);
    assert [token_amounts + 2 * Uint256.SIZE] = Uint256(1,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=caller,
        ids_len=3,
        ids=token_ids,
        amounts_len=3,
        amounts=token_amounts,
        data_len=0,
        data=null,
    );

    let (local balance_1 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(1,0));
    assert balance_1.low = 1;
    assert balance_1.high = 0;

    let (local balance_2 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(2,0));
    assert balance_2.low = 1;
    assert balance_2.high = 0;

    let (local balance_3 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(3,0));
    assert balance_3.low = 1;
    assert balance_3.high = 0;

    let (local resources_arr : Uint256*) = alloc(); 
    assert  [resources_arr] = Uint256(50,0);
    assert  [resources_arr + Uint256.SIZE] = Uint256(210,0);
    assert  [resources_arr + 2 * Uint256.SIZE] = Uint256(80,0);
    assert  [resources_arr + 3 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 4 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 5 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 6 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 7 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 8 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 9 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 10 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 11 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 12 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 13 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 14 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 15 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 16 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 17 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 18 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 19 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 20 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 21 * Uint256.SIZE] = Uint256(0,0);

 
    %{ stop_prank = start_prank(ids.caller) %}

    // Open Trade 
    IP2PMarket.open_trade(
        contract_address=p2p_contract_address,
        _token_ids_len=3, 
        _token_ids=token_ids, 
        _token_amounts_len=3, 
        _token_amounts=token_amounts, 
        _resources_needed_len=22,
        _resources_needed=resources_arr,
        _expiration=172800
    );

    %{ stop_prank() %}

    // CANCEL A TRADE RIGHT AFTER

    IP2PMarket.cancel_trade(
        contract_address=p2p_contract_address,
        _trade_id=counter
    );

    // check trade has been canceled

    let (trade : Trade) = IP2PMarket.get_trade(contract_address=p2p_contract_address, idx=counter);
    assert trade.status = TradeStatus.Cancelled; 
    return ();
}

// SHOULD PASS BECAUSE ENOUGH AMOUNTS FROM EXECUTOR
@external 
func test_execute_trade_success{syscall_ptr: felt*, range_check_ptr}(
){
    alloc_locals;
    local p2p_contract_address;
    local erc1155_address;
    local caller;
    local executor;
    %{
        ids.p2p_contract_address = context.p2p_market
        ids.erc1155_address = context.erc1155_address
        ids.caller = context.deployer_address
        ids.executor = 123456789987654322
    %}
    let (counter) = IP2PMarket.get_trade_counter(contract_address=p2p_contract_address);
    assert counter = 1;

    // OPEN A TRADE FIRST 
    // Mint batch a set of ids
    let (local token_ids : Uint256*) = alloc(); 
    assert [token_ids] = Uint256(1,0);
    assert [token_ids + Uint256.SIZE] = Uint256(2,0);
    assert [token_ids + 2 * Uint256.SIZE] = Uint256(3,0);

    let (local token_amounts : Uint256*) = alloc(); 
    assert [token_amounts] = Uint256(1,0);
    assert [token_amounts + Uint256.SIZE] = Uint256(1,0);
    assert [token_amounts + 2 * Uint256.SIZE] = Uint256(1,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=caller,
        ids_len=3,
        ids=token_ids,
        amounts_len=3,
        amounts=token_amounts,
        data_len=0,
        data=null,
    );

    let (local balance_1 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(1,0));
    assert balance_1.low = 1;
    assert balance_1.high = 0;

    let (local balance_2 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(2,0));
    assert balance_2.low = 1;
    assert balance_2.high = 0;

    let (local balance_3 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(3,0));
    assert balance_3.low = 1;
    assert balance_3.high = 0;

    let (local resources_arr : Uint256*) = alloc(); 
    assert  [resources_arr] = Uint256(50,0);
    assert  [resources_arr + Uint256.SIZE] = Uint256(210,0);
    assert  [resources_arr + 2 * Uint256.SIZE] = Uint256(80,0);
    assert  [resources_arr + 3 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 4 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 5 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 6 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 7 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 8 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 9 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 10 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 11 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 12 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 13 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 14 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 15 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 16 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 17 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 18 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 19 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 20 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 21 * Uint256.SIZE] = Uint256(0,0);
    
    %{ stop_prank = start_prank(ids.caller) %}

    // Open Trade 
    IP2PMarket.open_trade(
        contract_address=p2p_contract_address,
        _token_ids_len=3, 
        _token_ids=token_ids, 
        _token_amounts_len=3, 
        _token_amounts=token_amounts, 
        _resources_needed_len=22,
        _resources_needed=resources_arr,
        _expiration=172800
    );

    %{ stop_prank() %}

    // Mint batch ids to executor to have the required needs
    let (local token_ids_ex : Uint256*) = alloc(); 
    assert [token_ids_ex] = Uint256(1,0);
    assert [token_ids_ex + Uint256.SIZE] = Uint256(2,0);
    assert [token_ids_ex + 2 * Uint256.SIZE] = Uint256(3,0);

    let (local token_amounts_ex : Uint256*) = alloc(); 
    assert [token_amounts_ex] = Uint256(70,0);
    assert [token_amounts_ex + Uint256.SIZE] = Uint256(220,0);
    assert [token_amounts_ex + 2 * Uint256.SIZE] = Uint256(90,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=executor,
        ids_len=3,
        ids=token_ids_ex,
        amounts_len=3,
        amounts=token_amounts_ex,
        data_len=0,
        data=null,
    );

    let (local balance_1_ex : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=executor,id=Uint256(1,0));
    assert balance_1_ex.low = 70;
    assert balance_1_ex.high = 0;

    let (local balance_2_ex : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=executor,id=Uint256(2,0));
    assert balance_2_ex.low = 220;
    assert balance_2_ex.high = 0;

    let (local balance_3_ex : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=executor,id=Uint256(3,0));
    assert balance_3_ex.low = 90;
    assert balance_3_ex.high = 0;

    
    // EXECUTE A TRADE RIGHT AFTER
    %{ stop_prank = start_prank(ids.executor) %}

    IP2PMarket.execute_trade(
        contract_address=p2p_contract_address,
        _trade_id=counter
    );

    %{ stop_prank() %}


    // check trade has been executed

    let (trade : Trade) = IP2PMarket.get_trade(contract_address=p2p_contract_address, idx=counter);
    assert trade.status = TradeStatus.Executed; 
    return ();

}


// SHOULD FAIL BECAUSE NOT ENOUGH AMOUNTS FROM EXECUTOR
@external 
func test_execute_trade_fail{syscall_ptr: felt*, range_check_ptr}(
){
    alloc_locals;
    local p2p_contract_address;
    local erc1155_address;
    local caller;
    local executor;
    %{
        ids.p2p_contract_address = context.p2p_market
        ids.erc1155_address = context.erc1155_address
        ids.caller = context.deployer_address
        ids.executor = 123456789987654322
    %}
    let (counter) = IP2PMarket.get_trade_counter(contract_address=p2p_contract_address);
    assert counter = 1;

    // OPEN A TRADE FIRST 
    // Mint batch a set of ids
    let (local token_ids : Uint256*) = alloc(); 
    assert [token_ids] = Uint256(1,0);
    assert [token_ids + Uint256.SIZE] = Uint256(2,0);
    assert [token_ids + 2 * Uint256.SIZE] = Uint256(3,0);

    let (local token_amounts : Uint256*) = alloc(); 
    assert [token_amounts] = Uint256(1,0);
    assert [token_amounts + Uint256.SIZE] = Uint256(1,0);
    assert [token_amounts + 2 * Uint256.SIZE] = Uint256(1,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=caller,
        ids_len=3,
        ids=token_ids,
        amounts_len=3,
        amounts=token_amounts,
        data_len=0,
        data=null,
    );

    let (local balance_1 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(1,0));
    assert balance_1.low = 1;
    assert balance_1.high = 0;

    let (local balance_2 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(2,0));
    assert balance_2.low = 1;
    assert balance_2.high = 0;

    let (local balance_3 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(3,0));
    assert balance_3.low = 1;
    assert balance_3.high = 0;

    let (local resources_arr : Uint256*) = alloc(); 
    assert  [resources_arr] = Uint256(50,0);
    assert  [resources_arr + Uint256.SIZE] = Uint256(210,0);
    assert  [resources_arr + 2 * Uint256.SIZE] = Uint256(80,0);
    assert  [resources_arr + 3 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 4 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 5 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 6 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 7 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 8 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 9 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 10 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 11 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 12 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 13 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 14 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 15 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 16 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 17 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 18 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 19 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 20 * Uint256.SIZE] = Uint256(0,0);
    assert  [resources_arr + 21 * Uint256.SIZE] = Uint256(0,0);
    
    %{ stop_prank = start_prank(ids.caller) %}

    // Open Trade 
    IP2PMarket.open_trade(
        contract_address=p2p_contract_address,
        _token_ids_len=3, 
        _token_ids=token_ids, 
        _token_amounts_len=3, 
        _token_amounts=token_amounts, 
        _resources_needed_len=22,
        _resources_needed=resources_arr,
        _expiration=172800
    );

    %{ stop_prank() %}

    // Mint batch ids to executor to have the required needs
    let (local token_ids_ex : Uint256*) = alloc(); 
    assert [token_ids_ex] = Uint256(1,0);
    assert [token_ids_ex + Uint256.SIZE] = Uint256(2,0);
    assert [token_ids_ex + 2 * Uint256.SIZE] = Uint256(3,0);

    let (local token_amounts_ex : Uint256*) = alloc(); 
    assert [token_amounts_ex] = Uint256(30,0);
    assert [token_amounts_ex + Uint256.SIZE] = Uint256(10,0);
    assert [token_amounts_ex + 2 * Uint256.SIZE] = Uint256(90,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=executor,
        ids_len=3,
        ids=token_ids_ex,
        amounts_len=3,
        amounts=token_amounts_ex,
        data_len=0,
        data=null,
    );

    let (local balance_1_ex : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=executor,id=Uint256(1,0));
    assert balance_1_ex.low = 70;
    assert balance_1_ex.high = 0;

    let (local balance_2_ex : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=executor,id=Uint256(2,0));
    assert balance_2_ex.low = 220;
    assert balance_2_ex.high = 0;

    let (local balance_3_ex : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=executor,id=Uint256(3,0));
    assert balance_3_ex.low = 90;
    assert balance_3_ex.high = 0;

    
    // EXECUTE A TRADE RIGHT AFTER
    %{ stop_prank = start_prank(ids.executor) %}

    IP2PMarket.execute_trade(
        contract_address=p2p_contract_address,
        _trade_id=counter
    );

    %{ stop_prank() %}


    // check trade has been executed

    let (trade : Trade) = IP2PMarket.get_trade(contract_address=p2p_contract_address, idx=counter);
    assert trade.status = TradeStatus.Executed; 
    return ();

}



