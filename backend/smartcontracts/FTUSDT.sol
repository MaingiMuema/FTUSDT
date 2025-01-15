// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITRC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @title Flash USDT Token
 * @dev Implementation of the Flash USDT (FTUSDT) token with time-limited transaction functionality.
 * TRC-20 Token with flash loan capabilities, time restrictions, and security features.
 */
contract FTUSDT is ITRC20, Ownable, Pausable {
    string private constant _name = "Flash USDT";
    string private constant _symbol = "FTUSDT";
    uint8 private constant _decimals = 6;
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Flash transaction structures
    struct FlashTransaction {
        uint256 amount;
        uint256 deadline;
        bool executed;
        bool cancelled;
    }

    // Mapping for flash transactions
    mapping(bytes32 => FlashTransaction) private _flashTransactions;
    mapping(address => bytes32[]) private _userFlashTransactions;
    
    // Time window constraints for flash transactions (in seconds)
    uint256 public constant MIN_FLASH_WINDOW = 1 minutes;
    uint256 public constant MAX_FLASH_WINDOW = 24 hours;
    uint256 public constant MAX_FLASH_AMOUNT = 1000000 * 10**6; // 1M FTUSDT

    // Fee structure
    uint256 public flashFeePercentage = 1; // 0.1%
    address public feeCollector;
    
    // Events
    event FlashTransactionCreated(bytes32 indexed txId, address indexed sender, address indexed recipient, uint256 amount, uint256 deadline);
    event FlashTransactionExecuted(bytes32 indexed txId, address indexed sender, address indexed recipient, uint256 amount);
    event FlashTransactionCancelled(bytes32 indexed txId, address indexed sender);
    event FlashFeeUpdated(uint256 newFeePercentage);
    event FeeCollectorUpdated(address newFeeCollector);

    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply * 10**_decimals);
        feeCollector = msg.sender;
    }

    // Standard TRC20 functions with flash transaction checks
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!isFlashTransaction(msg.sender), "FTUSDT: sender has pending flash transaction");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        require(!isFlashTransaction(msg.sender), "FTUSDT: sender has pending flash transaction");
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!isFlashTransaction(sender), "FTUSDT: sender has pending flash transaction");
        
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "FTUSDT: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    /**
     * @dev Creates a new flash transaction with custom time window
     * @param recipient The recipient of the flash transaction
     * @param amount The amount of tokens to transfer
     * @param timeWindow The time window in seconds for the transaction to be valid
     * @return txId The unique identifier of the flash transaction
     */
    function createFlashTransaction(
        address recipient, 
        uint256 amount,
        uint256 timeWindow
    ) public whenNotPaused returns (bytes32) {
        require(amount <= MAX_FLASH_AMOUNT, "FTUSDT: amount exceeds maximum flash amount");
        require(recipient != address(0), "FTUSDT: invalid recipient");
        require(_balances[msg.sender] >= amount, "FTUSDT: insufficient balance");
        require(
            timeWindow >= MIN_FLASH_WINDOW && timeWindow <= MAX_FLASH_WINDOW,
            "FTUSDT: invalid time window"
        );

        uint256 deadline = block.timestamp + timeWindow;
        bytes32 txId = keccak256(
            abi.encodePacked(
                msg.sender, 
                recipient, 
                amount, 
                deadline, 
                block.timestamp
            )
        );

        _flashTransactions[txId] = FlashTransaction({
            amount: amount,
            deadline: deadline,
            executed: false,
            cancelled: false
        });

        _userFlashTransactions[msg.sender].push(txId);

        emit FlashTransactionCreated(txId, msg.sender, recipient, amount, deadline);
        return txId;
    }

    /**
     * @dev Creates a new flash transaction with default time window (15 minutes)
     * @param recipient The recipient of the flash transaction
     * @param amount The amount of tokens to transfer
     * @return txId The unique identifier of the flash transaction
     */
    function createFlashTransaction(
        address recipient, 
        uint256 amount
    ) public whenNotPaused returns (bytes32) {
        return createFlashTransaction(recipient, amount, 15 minutes);
    }

    /**
     * @dev Executes a flash transaction
     * @param txId The unique identifier of the flash transaction
     */
    function executeFlashTransaction(bytes32 txId) public whenNotPaused {
        FlashTransaction storage flashTx = _flashTransactions[txId];
        require(!flashTx.executed && !flashTx.cancelled, "FTUSDT: transaction already executed or cancelled");
        require(block.timestamp <= flashTx.deadline, "FTUSDT: transaction expired");

        address sender = recoverTransactionSender(txId);
        require(_balances[sender] >= flashTx.amount, "FTUSDT: insufficient balance");

        // Calculate and deduct fee
        uint256 feeAmount = (flashTx.amount * flashFeePercentage) / 1000;
        uint256 netAmount = flashTx.amount - feeAmount;

        // Transfer tokens
        _transfer(sender, msg.sender, netAmount);
        if (feeAmount > 0) {
            _transfer(sender, feeCollector, feeAmount);
        }

        flashTx.executed = true;
        emit FlashTransactionExecuted(txId, sender, msg.sender, flashTx.amount);
    }

    /**
     * @dev Cancels a flash transaction
     * @param txId The unique identifier of the flash transaction
     */
    function cancelFlashTransaction(bytes32 txId) public whenNotPaused {
        FlashTransaction storage flashTx = _flashTransactions[txId];
        require(!flashTx.executed, "FTUSDT: transaction already executed");
        require(!flashTx.cancelled, "FTUSDT: transaction already cancelled");
        
        address sender = recoverTransactionSender(txId);
        require(msg.sender == sender, "FTUSDT: not transaction sender");

        flashTx.cancelled = true;
        emit FlashTransactionCancelled(txId, sender);
    }

    /**
     * @dev Updates the flash fee percentage
     * @param newFeePercentage The new fee percentage (in basis points)
     */
    function updateFlashFee(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 10, "FTUSDT: fee too high"); // Max 1%
        flashFeePercentage = newFeePercentage;
        emit FlashFeeUpdated(newFeePercentage);
    }

    /**
     * @dev Updates the fee collector address
     * @param newFeeCollector The new fee collector address
     */
    function updateFeeCollector(address newFeeCollector) public onlyOwner {
        require(newFeeCollector != address(0), "FTUSDT: invalid fee collector");
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    /**
     * @dev Checks if an address has any pending flash transactions
     * @param account The address to check
     * @return bool True if the address has pending flash transactions
     */
    function isFlashTransaction(address account) public view returns (bool) {
        bytes32[] memory txIds = _userFlashTransactions[account];
        for (uint256 i = 0; i < txIds.length; i++) {
            FlashTransaction memory flashTx = _flashTransactions[txIds[i]];
            if (!flashTx.executed && !flashTx.cancelled && block.timestamp <= flashTx.deadline) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Gets flash transaction details
     * @param txId The unique identifier of the flash transaction
     * @return amount The transaction amount
     * @return deadline The transaction deadline
     * @return executed Whether the transaction has been executed
     * @return cancelled Whether the transaction has been cancelled
     */
    function getFlashTransaction(bytes32 txId) public view returns (
        uint256 amount,
        uint256 deadline,
        bool executed,
        bool cancelled
    ) {
        FlashTransaction memory flashTx = _flashTransactions[txId];
        return (flashTx.amount, flashTx.deadline, flashTx.executed, flashTx.cancelled);
    }

    /**
     * @dev Recovers the sender of a flash transaction
     * @param txId The unique identifier of the flash transaction
     * @return address The sender's address
     */
    function recoverTransactionSender(bytes32 txId) internal pure returns (address) {
        // Implementation would depend on how the txId is generated and signed
        // This is a placeholder implementation
        return address(uint160(uint256(txId)));
    }

    // Standard TRC20 functions remain unchanged...
    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }

    // Internal functions remain unchanged...
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

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "FTUSDT: approve from the zero address");
        require(spender != address(0), "FTUSDT: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "FTUSDT: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}
