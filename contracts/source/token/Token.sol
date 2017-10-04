pragma solidity ^0.4.15;

import "./IToken.sol";
import "../../infrastructure/modifier/InputValidator.sol";

/**
 * @title ERC20 compatible token
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
 * - Short address attack fix
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract Token is IToken, InputValidator {

    // Ethereum token standard
    string public standard = "Token 0.3";
    string public name;        
    string public symbol;
    uint8 public decimals = 8;

    // Token state
    uint internal totalTokenSupply;

    // Token balances
    mapping (address => uint) internal balances;

    // Token allowances
    mapping (address => mapping (address => uint)) internal allowed;


    // Events
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    /** 
     * Construct 
     * 
     * @param _name The full token name
     * @param _symbol The token symbol (aberration)
     */
    function Token(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        balances[msg.sender] = 0;
        totalTokenSupply = 0;
    }


    /** 
     * Get the total token supply
     * 
     * @return The total supply
     */
    function totalSupply() public constant returns (uint) {
        return totalTokenSupply;
    }


    /** 
     * Get balance of `_owner` 
     * 
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }


    /** 
     * Send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint _value) public safe_arguments(2) returns (bool) {

        // Check if the sender has enough tokens
        require(balances[msg.sender] >= _value);   

        // Check for overflows
        require(balances[_to] + _value > balances[_to]);

        // Transfer tokens
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Notify listeners
        Transfer(msg.sender, _to, _value);
        return true;
    }


    /** 
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not 
     */
    function transferFrom(address _from, address _to, uint _value) public safe_arguments(3) returns (bool) {

        // Check if the sender has enough
        require(balances[_from] >= _value);

        // Check for overflows
        require(balances[_to] + _value > balances[_to]);

        // Check allowance
        require(_value <= allowed[_from][msg.sender]);

        // Transfer tokens
        balances[_to] += _value;
        balances[_from] -= _value;

        // Update allowance
        allowed[_from][msg.sender] -= _value;

        // Notify listeners
        Transfer(_from, _to, _value);
        return true;
    }


    /** 
     * `msg.sender` approves `_spender` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint _value) public safe_arguments(2) returns (bool) {

        // Update allowance
        allowed[msg.sender][_spender] = _value;

        // Notify listeners
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /** 
     * Get the amount of remaining tokens that `_spender` is allowed to spend from `_owner`
     * 
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) public constant returns (uint) {
      return allowed[_owner][_spender];
    }
}
