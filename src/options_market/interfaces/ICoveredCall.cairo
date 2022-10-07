%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.utils.options_market.covered_call import (
    CallOption
)
@contract_interface
namespace ICoveredCall {
    func bid(option_id : felt, bid_amount : felt) {
    }

    func write(token_address : felt, token_id : felt, strike : felt, expiration_time : felt) {
    }

    func buy(option_id : felt) {
    }

    func settle(option_id : felt) {
    }

    func reclaim_underlying(option_id : felt) {
    }

    func claim_option_earnings(option_id : felt) {
    }

    func burn_expired_option(option_id : felt) {
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