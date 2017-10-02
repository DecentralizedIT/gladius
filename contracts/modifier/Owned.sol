pragma solidity ^0.4.15;

contract Owned {

    // The address of the account that is the current owner 
    address public owner;

    // The publiser is the inital owner
    function Owned() {
        owner = msg.sender;
    }

    /**
     * Access is restricted to the current owner
     */
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}