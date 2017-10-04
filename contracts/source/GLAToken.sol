pragma solidity ^0.4.15;

import "./token/IToken.sol";
import "./token/ManagedToken.sol";

/**
 * @title GLA (Gladius) token
 *
 * #created 26/09/2017
 * #author Frank Bonnet
 */
contract GLAToken is ManagedToken {


    /**
     * Starts with a total supply of zero and the creator starts with 
     * zero tokens (just like everyone else)
     */
    function GLAToken() ManagedToken("Gladius Token", "GLA", true) {}


    /**
     * Failsafe mechanism
     * 
     * Allowes owner to extract tokens from the contract
     */
    function extractToken(address _tokenContract, uint _value) public only_owner {
        IToken _tokenInstance = IToken(_tokenContract);
        _tokenInstance.transfer(owner, _value);
    }


    /**
     * Prevents accidental sending of ether
     */
    function () payable {
        revert();
    }
}
