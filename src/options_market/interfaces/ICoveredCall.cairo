%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.utils.options_market.covered_call import (
    CallOption
)
@contract_interface
namespace ICoveredCall {
    func bid(option_id : Uint256, bid_amount : felt) {
    }

    func write(
        token_id : Uint256,
        strike : Uint256,
        expiration_time : felt
    ) {
    }

    func buy(option_id : Uint256) {
    }

    func settle(option_id : Uint256) {
    }

    func reclaim_underlying(option_id : Uint256) {
    }

    func claim_option_earnings(option_id : Uint256) {
    }

    func burn_expired_option(option_id : Uint256) {
    }

    
    func get_settlement_token_address(
    )-> (address : felt){
    }

    
    func get_underlying_token_address(
    )-> (address : felt){
    }

    
    func get_nft_address(
    )-> (address : felt){
    }

    
    func get_open_interest(
    )-> (res : Uint256){
    }

    
    func get_option_item(
        idx : Uint256
    )-> (res : CallOption){
    }

    
    func get_black_scholes_address(
    )-> (address : felt){
    }
}