%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from src.p2p_resources_market.interfaces.IP2PMarket import IP2PMarket
from src.common.interfaces.IAssetErc1155 import IAssetErc1155

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
        context.erc1155_address = deploy_contract("./src/common/asset_erc1155.cairo").contract_address 
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
        _expiration=17280009888,
    );
    %{ stop_prank() %}

    // check new trade inserted

    let (trade : Trade) = IP2PMarket.get_trade(contract_address=contract_address, idx=counter);
    assert trade.owner = 123456789987654321;
    assert trade.asset_contract = res;
    assert trade.asset_ids_len = 3;
    assert trade.asset_amounts_len = 3;
    assert trade.status = TradeStatus.Open; 
    assert trade.expiration = 17280009888;

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





