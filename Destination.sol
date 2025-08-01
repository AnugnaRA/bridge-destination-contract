
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

	function createToken(address underlying, string memory name, string memory symbol) external onlyRole(CREATOR_ROLE) returns (address) {
    require(wrapped_tokens[underlying] == address(0), "Token already created");
    
    BridgeToken token = new BridgeToken(underlying, name, symbol, address(this));
    
    wrapped_tokens[underlying] = address(token);
    underlying_tokens[address(token)] = underlying;
    
    emit Creation(underlying, address(token));
    return address(token);
	}
	
	function wrap(address underlying, address recipient, uint256 amount) external onlyRole(WARDEN_ROLE) {
    address tokenAddress = wrapped_tokens[underlying];
    require(tokenAddress != address(0), "Token not registered");
    
    BridgeToken token = BridgeToken(tokenAddress);
    token.mint(recipient, amount);
    
    emit Wrap(underlying, tokenAddress, recipient, amount);
	}
	
	function unwrap(address tokenAddress, address recipient, uint256 amount) external {
    BridgeToken token = BridgeToken(tokenAddress);
    
    // Get the underlying address from the token
    address underlying = token.underlying();
    
    // This will burn the tokens from msg.sender
    token.burnFrom(msg.sender, amount);
    
    // Emit the unwrap event with all required parameters
    emit Unwrap(underlying, tokenAddress, msg.sender, recipient, amount);
	}
}
