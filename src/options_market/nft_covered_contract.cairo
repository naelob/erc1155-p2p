
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt
){
    ERC721.initializer(name, symbol);
    // TODO : Ownable.initializer(owner);

    return ();
}

//GETTERS

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (owner: felt) {
    return ERC721.owner_of(token_id);
}

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt){
    let (name) = ERC721.name();
    return (name=name);
}

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt){
    let (symbol) = ERC721.symbol();
    return (symbol=symbol);
}

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
){
    let (balance : Uint256) = ERC721.balance_of(owner);
    return (balance=balance);
}

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (approved : felt){
    let (approved : felt) = ERC721.get_approved(tokenId);
    return (approved=approved);
}

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (isApproved : felt){
    let (isApproved : felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt){
    let (success) = ERC165.supports_interface(interfaceId);
    return (success=success);
}

//EXTERNAL

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, token_id: Uint256, data_len: felt, data: felt*
) {
    // todo : add ownable Ownable.assert_only_owner()
    ERC721._safe_mint(to, token_id, data_len, data);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256    
) {
    // todo : add ownable Ownable.assert_only_owner()
    ERC721._burn(token_id);
    return ();
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, token_id: Uint256
) {
    ERC721.transfer_from(from_, to, token_id);
    return();
}

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, tokenId : Uint256
){
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
){
    ERC721.set_approval_for_all(operator, approved);
    return ();
}
