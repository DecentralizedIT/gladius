pragma solidity ^0.4.15;

import "./ITransferableOwnership.sol";
import "./Ownership.sol";

contract TransferableOwnership is ITransferableOwnership, Ownership {


    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}
