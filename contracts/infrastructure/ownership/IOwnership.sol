pragma solidity ^0.4.15;

contract IOwnership {

    /**
     * Returns true if `_account` is the current owner
     *
     * @param _account The address to test against
     */
    function isOwner(address _account) constant returns (bool);


    /**
     * Gets the current owner
     *
     * @return address The current owner
     */
    function getOwner() constant returns (address);
}
