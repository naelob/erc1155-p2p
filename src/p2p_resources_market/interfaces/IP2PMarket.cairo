%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.p2p_resources_market.p2p_market import (
    Trade,
)
@contract_interface
namespace IP2PMarket {
    
    func open_trade(
        _token_ids_len : felt, 
        _token_ids: Uint256*, 
        _token_amounts_len : felt,
        _token_amounts : Uint256*, 
        _resources_needed_len : felt,
        _resources_needed : felt*,
        _expiration : felt
    ){
    }

    func execute_trade(_trade_id : felt){
    }

    func cancel_trade(_trade_id: felt){
    }

    func get_asset_address() -> (res : felt) {
    }

    func get_trade_counter() -> (value: felt) {
    }

    func get_trade(idx: felt) -> (trade: Trade) {
    }


}