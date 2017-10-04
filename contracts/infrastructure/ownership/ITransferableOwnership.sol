pragma solidity ^0.4.15;

contract ITransferableOwnership {

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner);
}
