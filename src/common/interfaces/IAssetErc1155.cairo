%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAssetErc1155 {

    func mint(
        to: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
    ) {
    }

    func batchMint(
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) {
    }

    func burn(
        from_: felt, id: Uint256, amount: Uint256
    ) {
    }

    func batchBurn(
        from_: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
    }

    func batchTransferFrom(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) {
    }


    func balanceOf(account: felt, id: Uint256) -> (
        balance : Uint256
    ){
    } 
}