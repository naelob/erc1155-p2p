%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from src.p2p_resources_market.interfaces.ICoveredCall import ICoveredCall
from src.p2p_resources_market.interfaces.INftCoveredContract import INftCoveredContract
from src.p2p_resources_market.interfaces.IAssetErc1155 import IAssetErc1155

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

// TEST SUITE FOR SPOT MODE ONLY

@external
func __setup__() {
    tempvar deployer_address = 123456789987654321;
    tempvar settlement_token = ;
    tempvar black_scholes_address = ;
    tempvar exchange_amm_address = ;
    %{ 
        context.deployer_address = ids.deployer_address
        context.settlement_token = ids.settlement_token
        context.black_scholes_address = ids.black_scholes_address
        context.erc1155_address = deploy_contract("./src/p2p_resources_market/asset_erc1155.cairo").contract_address 
        context.nft_covered_contract = deploy_contract("./src/options_market/nft_covered_contract.cairo").contract_address 
        context.covered_call = deploy_contract("./src/options_market/covered_call.cairo", 
            [
                context.deployer_address, 
                context.settlement_token,
                context.nft_covered_contract,
                1,
                1,
                864000,
                context.black_scholes_address,
                context.exchange_amm_address,
                context.erc1155_address
            ]).contract_address 
    %}
    return ();
}

@external
func test_storage_init{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {

    local covered_call_address;
    local erc1155_address;
    local caller;

    local settlement; 
    local bs;
    local min_above_bid_alpha;
    local exchange_amm_address;
    local nft_covered_contract;
    %{ 
        ids.erc1155_address = context.erc1155_address
        ids.covered_call_address = context.covered_call
        ids.caller = context.deployer_address
        ids.settlement = context.settlement_token
        ids.bs = context.black_scholes_address
        ids.min_above_bid_alpha = context.min_above_bid_alpha
        ids.exchange_amm_address = context.exchange_amm_address
        ids.nft_covered_contract = context.nft_covered_contract
    %}
    let (address) = ICoveredCall.get_settlement_token_address(contract_address=covered_call_address);
    assert address = settlement;

    let (erc1155) = ICoveredCall.get_underlying_token_address(contract_address=covered_call_address);
    assert erc1155 = erc1155_address;

    let (NFT) = ICoveredCall.get_nft_address(contract_address=covered_call_address);
    assert NFT = nft_covered_contract;

    let (BS) = ICoveredCall.get_black_scholes_address(contract_address=covered_call_address);
    assert BS = bs;

    let (counter) = ICoveredCall.get_open_interest(contract_address=covered_call_address);
    assert counter.low = 1;
    assert counter.high = 0;


}

@external
func test_write_call_option{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    
    local covered_call_address;
    local erc1155_address;
    local caller;
    local nft_covered_contract;
    %{ 
        ids.erc1155_address = context.erc1155_address
        ids.covered_call_address = context.covered_call
        ids.caller = context.deployer_address
        ids.settlement = context.settlement_token
        ids.bs = context.black_scholes_address
        ids.min_above_bid_alpha = context.min_above_bid_alpha
        ids.exchange_amm_address = context.exchange_amm_address
        ids.nft_covered_contract = context.nft_covered_contract
    %}

    // Mint one erc1155 to deployer

    // Mint batch a set of ids
    let (local token_ids : Uint256*) = alloc(); 
    assert [token_ids] = Uint256(1,0);

    let (local token_amounts : Uint256*) = alloc(); 
    assert [token_amounts] = Uint256(1,0);

    let (local null : felt*) = alloc(); 

    IAssetErc1155.batchMint(
        contract_address=erc1155_address,
        to=caller,
        ids_len=1,
        ids=token_ids,
        amounts_len=1,
        amounts=token_amounts,
        data_len=0,
        data=null,
    );

    let (local balance_1 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(1,0));
    assert balance_1.low = 1;
    assert balance_1.high = 0;
    
    %{ stop_prank = start_prank(context.deployer_address,ids.contract_address) %}

    ICoveredCall.write(
        contract_address=covered_call_address,
        token_address=erc1155_address, 
        token_id=Uint256(1,0), 
        strike=Uint256(120,0), 
        expiration_time=869000
    );

    %{ stop_prank() %}

    // Check we dont own anymore the erc1155
    let (local balance_2 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=caller,id=Uint256(1,0));
    assert balance_2.low = 0;
    assert balance_2.high = 0;

    //Check contract owns the underlying
    let (local balance_3 : Uint256) = IAssetErc1155.balanceOf(contract_address=erc1155_address,account=covered_call_address,id=Uint256(1,0));
    assert balance_3.low = 1;
    assert balance_3.high = 0;

    // Check we received an NFT representation of the option contract just opened
    let (local balance_nft : Uint256) = INftCoveredContract.balanceOf(contract_address=nft_covered_contract,owner=caller);
    assert balance_nft.low = 1;
    assert balance_nft.high = 0;
    
    let (counter) = ICoveredCall.get_open_interest(contract_address=covered_call_address);
    assert counter.low = 1;
    assert counter.high = 0;

    // Check option has been registered in storage
    let (call_opt : CallOption) = ICoveredCall.get_option_item(
        contract_address=covered_call_address
        idx=counter
    );

    assert call_opt.Writer = caller;
    assert call_opt.Expiration = 869000;
    assert call_opt.Strike.low = 120;
    assert call_opt.Strike.high = 0;
    assert call_opt.Settled = 1;
    assert call_opt.AssetId.low = 1;
    assert call_opt.AssetId.high = 0;

    return ();

}

@external
func test_buy_call_option{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    
}

@external
func test_settle_call_option{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    
}

@external
func test_reclaim_underlying{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    
}
