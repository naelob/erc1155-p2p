%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from src.p2p_resources_market.interfaces.ICoveredCall import ICoveredCall
from src.p2p_resources_market.interfaces.INftCoveredContract import INftCoveredContract

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


}

@external
func test_write_call_option{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    
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
