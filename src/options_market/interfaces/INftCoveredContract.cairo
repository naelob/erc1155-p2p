%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace INftCoveredContract {
    func mint(
        to: felt, token_id: Uint256, data_len: felt, data: felt*
    ) {
    }

    func burn(
        token_id: Uint256    
    ) {
    }

    func ownerOf(
        token_id: Uint256
    ) -> (owner: felt) {
    }

    func transferFrom(
        from_: felt, to: felt, token_id: Uint256
    ) {
    }
    
}