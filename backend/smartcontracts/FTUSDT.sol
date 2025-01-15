// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITRC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @title Flash USDT Token
 * @dev Implementation of the Flash USDT (FTUSDT) token.
 * TRC-20 Token with pausable and ownable functionality.
 */
contract FTUSDT is ITRC20, Ownable, Pausable {
    string private constant _name = "Flash USDT";
    string private constant _symbol = "FTUSDT";
    uint8 private constant _decimals = 6;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Blacklist functionality
    mapping(address => bool) private _blacklisted;
    
    // Events
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event TokensBurned(address indexed from, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @param initialSupply The initial supply of tokens
     */
    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply * 10**_decimals);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of tokens.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of the specified address.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklisted[msg.sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[recipient], "FTUSDT: recipient is blacklisted");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     */
    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklisted[msg.sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[spender], "FTUSDT: spender is blacklisted");
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklisted[sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[recipient], "FTUSDT: recipient is blacklisted");
        require(!_blacklisted[msg.sender], "FTUSDT: spender is blacklisted");
        
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "FTUSDT: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    /**
     * @dev Adds an account to the blacklist.
     */
    function blacklist(address account) public onlyOwner {
        require(!_blacklisted[account], "FTUSDT: account is already blacklisted");
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Removes an account from the blacklist.
     */
    function unBlacklist(address account) public onlyOwner {
        require(_blacklisted[account], "FTUSDT: account is not blacklisted");
        _blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    /**
     * @dev Checks if an account is blacklisted.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev Burns tokens from the caller's account.
     */
    function burn(uint256 amount) public whenNotPaused {
        require(!_blacklisted[msg.sender], "FTUSDT: sender is blacklisted");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Mints new tokens. Only callable by the owner.
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        require(!_blacklisted[to], "FTUSDT: recipient is blacklisted");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Internal transfer function.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "FTUSDT: transfer from the zero address");
        require(recipient != address(0), "FTUSDT: transfer to the zero address");
        require(_balances[sender] >= amount, "FTUSDT: transfer amount exceeds balance");

        unchecked {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Internal approve function.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "FTUSDT: approve from the zero address");
        require(spender != address(0), "FTUSDT: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Internal mint function.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "FTUSDT: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] = _balances[account] + amount;
        }
        
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Internal burn function.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "FTUSDT: burn from the zero address");
        require(_balances[account] >= amount, "FTUSDT: burn amount exceeds balance");

        unchecked {
            _balances[account] = _balances[account] - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Pause token transfers. Only callable by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers. Only callable by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
