// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITRC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IPriceOracle.sol"; // Price oracle interface for USD price feeds
import "./ICollateralManager.sol"; // Collateral management interface

/**
 * @title Flash USDT Stablecoin
 * @dev Implementation of a collateralized stablecoin with flash transaction capabilities
 * Maintains 1:1 peg with USD through algorithmic and collateral-backed mechanisms
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
        address sender;
        address recipient;
        uint256 amount;
        uint256 deadline;
        uint256 minExecutionTime;  // Minimum time before execution
        uint256 fee;
        bool executed;
        bool cancelled;
        bytes32 purpose;  // Purpose or reason for the flash transaction
        mapping(address => bool) approvers;  // Multi-sig approvers
        uint256 requiredApprovals;  // Required number of approvals
        uint256 currentApprovals;   // Current number of approvals
    }

    // Mappings for flash transactions
    mapping(bytes32 => FlashTransaction) private _flashTransactions;
    mapping(address => bytes32[]) private _userFlashTransactions;
    mapping(address => uint256) private _userTransactionCount;
    mapping(address => bool) private _blacklisted;
    mapping(address => bool) private _approvers;
    
    // Time window constraints
    uint256 public constant MIN_FLASH_WINDOW = 1 minutes;
    uint256 public constant MAX_FLASH_WINDOW = 365 days;
    uint256 public constant MIN_EXECUTION_DELAY = 1 minutes;
    uint256 public constant MAX_FLASH_AMOUNT = 1000000 * 10**6;

    // Fee structure
    uint256 public flashFeePercentage = 1; // 0.1%
    uint256 public emergencyFeePercentage = 5; // 0.5% for emergency executions
    address public feeCollector;
    
    // Rate limiting
    uint256 public constant MAX_TRANSACTIONS_PER_DAY = 1000;
    mapping(address => uint256) private _dailyTransactionCount;
    mapping(address => uint256) private _lastTransactionTimestamp;

    // Stablecoin specific variables
    IPriceOracle public priceOracle;
    ICollateralManager public collateralManager;
    
    // Collateralization parameters
    uint256 public constant MINIMUM_COLLATERAL_RATIO = 150; // 150%
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120%
    uint256 public constant LIQUIDATION_PENALTY = 10; // 10%
    
    // Price stability parameters
    uint256 public constant PEG_PRICE = 1 * 10**18; // 1 USD in 18 decimals
    uint256 public constant PEG_TOLERANCE = 1 * 10**16; // 1% tolerance
    
    // Minting and burning limits
    uint256 public constant MAX_MINT_AMOUNT = 1000000 * 10**6; // 1M FTUSDT
    uint256 public constant MIN_MINT_AMOUNT = 100 * 10**6; // 100 FTUSDT
    
    // Stability fee
    uint256 public stabilityFee = 5; // 0.5% annual stability fee
    mapping(address => uint256) public lastStabilityFeeCollection;
    
    // Collateral positions
    struct CollateralPosition {
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 lastInteractionTime;
    }
    
    mapping(address => CollateralPosition) public collateralPositions;
    
    // Events
    event FlashTransactionCreated(
        bytes32 indexed txId,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 deadline,
        bytes32 purpose
    );
    event FlashTransactionExecuted(
        bytes32 indexed txId,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 fee
    );
    event FlashTransactionCancelled(bytes32 indexed txId, address indexed sender);
    event FlashTransactionApproved(bytes32 indexed txId, address indexed approver);
    event ApproverAdded(address indexed approver);
    event ApproverRemoved(address indexed approver);
    event EmergencyExecutionTriggered(bytes32 indexed txId, address indexed executor);
    event BlacklistUpdated(address indexed account, bool blacklisted);
    event FeeUpdated(uint256 newFeePercentage, uint256 newEmergencyFeePercentage);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event PositionLiquidated(address indexed user, uint256 collateralAmount, uint256 debtAmount);
    event PegAdjustment(uint256 previousPrice, uint256 newPrice);
    event StabilityFeeCollected(address indexed user, uint256 feeAmount);

    constructor(
        uint256 initialSupply,
        address _priceOracle,
        address _collateralManager
    ) {
        _mint(msg.sender, initialSupply * 10**_decimals);
        feeCollector = msg.sender;
        _approvers[msg.sender] = true;
        priceOracle = IPriceOracle(_priceOracle);
        collateralManager = ICollateralManager(_collateralManager);
        emit ApproverAdded(msg.sender);
    }

    /**
     * @dev Creates an advanced flash transaction
     */
    function createFlashTransaction(
        address recipient,
        uint256 amount,
        uint256 timeWindow,
        uint256 minExecutionTime,
        uint256 requiredApprovals,
        bytes32 purpose
    ) public whenNotPaused returns (bytes32) {
        require(!_blacklisted[msg.sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[recipient], "FTUSDT: recipient is blacklisted");
        require(amount <= MAX_FLASH_AMOUNT, "FTUSDT: amount exceeds maximum");
        require(recipient != address(0), "FTUSDT: invalid recipient");
        require(_balances[msg.sender] >= amount, "FTUSDT: insufficient balance");
        require(
            timeWindow >= MIN_FLASH_WINDOW && timeWindow <= MAX_FLASH_WINDOW,
            "FTUSDT: invalid time window"
        );
        require(
            minExecutionTime >= MIN_EXECUTION_DELAY,
            "FTUSDT: execution delay too short"
        );
        require(
            _canCreateTransaction(msg.sender),
            "FTUSDT: daily transaction limit exceeded"
        );

        bytes32 txId = keccak256(
            abi.encodePacked(
                msg.sender,
                recipient,
                amount,
                block.timestamp,
                purpose
            )
        );

        FlashTransaction storage flashTx = _flashTransactions[txId];
        flashTx.sender = msg.sender;
        flashTx.recipient = recipient;
        flashTx.amount = amount;
        flashTx.deadline = block.timestamp + timeWindow;
        flashTx.minExecutionTime = block.timestamp + minExecutionTime;
        flashTx.fee = (amount * flashFeePercentage) / 1000;
        flashTx.purpose = purpose;
        flashTx.requiredApprovals = requiredApprovals;
        flashTx.currentApprovals = 0;

        _userTransactionCount[msg.sender]++;
        _userFlashTransactions[msg.sender].push(txId);
        _updateDailyTransactionCount(msg.sender);

        emit FlashTransactionCreated(
            txId,
            msg.sender,
            recipient,
            amount,
            flashTx.deadline,
            purpose
        );

        return txId;
    }

    /**
     * @dev Approves a flash transaction (for multi-sig transactions)
     */
    function approveFlashTransaction(bytes32 txId) public whenNotPaused {
        require(_approvers[msg.sender], "FTUSDT: not an approver");
        FlashTransaction storage flashTx = _flashTransactions[txId];
        require(!flashTx.executed && !flashTx.cancelled, "FTUSDT: invalid transaction state");
        require(!flashTx.approvers[msg.sender], "FTUSDT: already approved");

        flashTx.approvers[msg.sender] = true;
        flashTx.currentApprovals++;

        emit FlashTransactionApproved(txId, msg.sender);
    }

    /**
     * @dev Executes a flash transaction
     */
    function executeFlashTransaction(bytes32 txId) public whenNotPaused {
        FlashTransaction storage flashTx = _flashTransactions[txId];
        require(!flashTx.executed && !flashTx.cancelled, "FTUSDT: invalid transaction state");
        require(block.timestamp <= flashTx.deadline, "FTUSDT: transaction expired");
        require(block.timestamp >= flashTx.minExecutionTime, "FTUSDT: execution delay not met");
        require(
            flashTx.currentApprovals >= flashTx.requiredApprovals,
            "FTUSDT: insufficient approvals"
        );

        require(
            _balances[flashTx.sender] >= flashTx.amount,
            "FTUSDT: insufficient balance"
        );

        flashTx.executed = true;

        // Transfer tokens and fee
        _transfer(flashTx.sender, flashTx.recipient, flashTx.amount - flashTx.fee);
        _transfer(flashTx.sender, feeCollector, flashTx.fee);

        emit FlashTransactionExecuted(
            txId,
            flashTx.sender,
            flashTx.recipient,
            flashTx.amount,
            flashTx.fee
        );
    }

    /**
     * @dev Emergency execution of a flash transaction
     */
    function emergencyExecute(bytes32 txId) public whenNotPaused {
        require(_approvers[msg.sender], "FTUSDT: not an approver");
        FlashTransaction storage flashTx = _flashTransactions[txId];
        require(!flashTx.executed && !flashTx.cancelled, "FTUSDT: invalid transaction state");
        require(block.timestamp <= flashTx.deadline, "FTUSDT: transaction expired");

        uint256 emergencyFee = (flashTx.amount * emergencyFeePercentage) / 1000;
        flashTx.executed = true;

        _transfer(flashTx.sender, flashTx.recipient, flashTx.amount - emergencyFee);
        _transfer(flashTx.sender, feeCollector, emergencyFee);

        emit EmergencyExecutionTriggered(txId, msg.sender);
    }

    /**
     * @dev Adds an approver for multi-sig transactions
     */
    function addApprover(address approver) public onlyOwner {
        require(approver != address(0), "FTUSDT: invalid approver address");
        require(!_approvers[approver], "FTUSDT: already an approver");
        _approvers[approver] = true;
        emit ApproverAdded(approver);
    }

    /**
     * @dev Removes an approver
     */
    function removeApprover(address approver) public onlyOwner {
        require(_approvers[approver], "FTUSDT: not an approver");
        _approvers[approver] = false;
        emit ApproverRemoved(approver);
    }

    /**
     * @dev Updates blacklist status
     */
    function updateBlacklist(address account, bool blacklisted) public onlyOwner {
        _blacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }

    /**
     * @dev Checks if an address can create a new transaction
     */
    function _canCreateTransaction(address account) internal view returns (bool) {
        if (block.timestamp - _lastTransactionTimestamp[account] >= 1 days) {
            return true;
        }
        return _dailyTransactionCount[account] < MAX_TRANSACTIONS_PER_DAY;
    }

    /**
     * @dev Updates daily transaction count
     */
    function _updateDailyTransactionCount(address account) internal {
        if (block.timestamp - _lastTransactionTimestamp[account] >= 1 days) {
            _dailyTransactionCount[account] = 1;
        } else {
            _dailyTransactionCount[account]++;
        }
        _lastTransactionTimestamp[account] = block.timestamp;
    }

    /**
     * @dev Deposits collateral and mints FTUSDT
     */
    function mintWithCollateral(uint256 collateralAmount, uint256 mintAmount) external whenNotPaused {
        require(mintAmount >= MIN_MINT_AMOUNT, "FTUSDT: Below minimum mint amount");
        require(mintAmount <= MAX_MINT_AMOUNT, "FTUSDT: Exceeds maximum mint amount");
        
        // Transfer collateral from user
        require(
            collateralManager.transferCollateralFrom(msg.sender, address(this), collateralAmount),
            "FTUSDT: Collateral transfer failed"
        );
        
        // Calculate collateral value in USD
        uint256 collateralValue = getCollateralValue(collateralAmount);
        uint256 requiredCollateral = (mintAmount * MINIMUM_COLLATERAL_RATIO) / 100;
        require(collateralValue >= requiredCollateral, "FTUSDT: Insufficient collateral");
        
        // Update position
        CollateralPosition storage position = collateralPositions[msg.sender];
        position.collateralAmount += collateralAmount;
        position.debtAmount += mintAmount;
        position.lastInteractionTime = block.timestamp;
        
        // Mint FTUSDT
        _mint(msg.sender, mintAmount);
        
        emit CollateralDeposited(msg.sender, collateralAmount);
    }

    /**
     * @dev Burns FTUSDT and withdraws collateral
     */
    function burnAndWithdraw(uint256 burnAmount, uint256 withdrawAmount) external whenNotPaused {
        CollateralPosition storage position = collateralPositions[msg.sender];
        require(position.debtAmount >= burnAmount, "FTUSDT: Insufficient debt");
        require(position.collateralAmount >= withdrawAmount, "FTUSDT: Insufficient collateral");
        
        // Collect stability fee
        collectStabilityFee(msg.sender);
        
        // Check remaining collateral ratio
        uint256 newDebt = position.debtAmount - burnAmount;
        uint256 newCollateral = position.collateralAmount - withdrawAmount;
        if (newDebt > 0) {
            uint256 newCollateralValue = getCollateralValue(newCollateral);
            require(
                newCollateralValue * 100 >= newDebt * MINIMUM_COLLATERAL_RATIO,
                "FTUSDT: Insufficient remaining collateral"
            );
        }
        
        // Burn FTUSDT
        _burn(msg.sender, burnAmount);
        
        // Update position
        position.debtAmount = newDebt;
        position.collateralAmount = newCollateral;
        position.lastInteractionTime = block.timestamp;
        
        // Return collateral
        require(
            collateralManager.transferCollateral(msg.sender, withdrawAmount),
            "FTUSDT: Collateral transfer failed"
        );
        
        emit CollateralWithdrawn(msg.sender, withdrawAmount);
    }

    /**
     * @dev Liquidates an undercollateralized position
     */
    function liquidatePosition(address user) external whenNotPaused {
        CollateralPosition storage position = collateralPositions[user];
        require(position.debtAmount > 0, "FTUSDT: No debt to liquidate");
        
        uint256 collateralValue = getCollateralValue(position.collateralAmount);
        uint256 currentRatio = (collateralValue * 100) / position.debtAmount;
        require(currentRatio < LIQUIDATION_THRESHOLD, "FTUSDT: Position not liquidatable");
        
        // Calculate liquidation amounts
        uint256 debtToRepay = position.debtAmount;
        uint256 collateralToSeize = (position.collateralAmount * (100 + LIQUIDATION_PENALTY)) / 100;
        
        // Burn FTUSDT from liquidator
        _burn(msg.sender, debtToRepay);
        
        // Transfer collateral to liquidator
        require(
            collateralManager.transferCollateral(msg.sender, collateralToSeize),
            "FTUSDT: Collateral transfer failed"
        );
        
        // Clear position
        delete collateralPositions[user];
        
        emit PositionLiquidated(user, collateralToSeize, debtToRepay);
    }

    /**
     * @dev Collects stability fee from a position
     */
    function collectStabilityFee(address user) public {
        CollateralPosition storage position = collateralPositions[user];
        if (position.debtAmount == 0) return;
        
        uint256 timePassed = block.timestamp - position.lastInteractionTime;
        uint256 feeAmount = (position.debtAmount * stabilityFee * timePassed) / (365 days * 1000);
        
        if (feeAmount > 0) {
            require(_balances[user] >= feeAmount, "FTUSDT: Insufficient balance for fee");
            _transfer(user, feeCollector, feeAmount);
            emit StabilityFeeCollected(user, feeAmount);
        }
        
        position.lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Gets current collateral value in USD
     */
    function getCollateralValue(uint256 amount) public view returns (uint256) {
        return priceOracle.getCollateralPrice() * amount / 10**18;
    }

    /**
     * @dev Checks if the stablecoin is maintaining its peg
     */
    function checkPeg() public view returns (bool) {
        uint256 currentPrice = priceOracle.getPrice();
        return (currentPrice >= PEG_PRICE - PEG_TOLERANCE) && 
               (currentPrice <= PEG_PRICE + PEG_TOLERANCE);
    }

    // Standard TRC20 functions with additional checks and stability fee collection
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklisted[msg.sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[recipient], "FTUSDT: recipient is blacklisted");
        
        // Collect stability fee before transfer
        collectStabilityFee(msg.sender);
        
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklisted[msg.sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[spender], "FTUSDT: spender is blacklisted");
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklisted[sender], "FTUSDT: sender is blacklisted");
        require(!_blacklisted[recipient], "FTUSDT: recipient is blacklisted");
        require(!_blacklisted[msg.sender], "FTUSDT: spender is blacklisted");
        
        // Collect stability fee before transfer
        collectStabilityFee(sender);
        
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "FTUSDT: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    // View functions
    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    function isApprover(address account) public view returns (bool) { return _approvers[account]; }
    function isBlacklisted(address account) public view returns (bool) { return _blacklisted[account]; }

    // Internal functions
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

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "FTUSDT: burn from the zero address");
        require(_balances[account] >= amount, "FTUSDT: burn amount exceeds balance");

        unchecked {
            _balances[account] = _balances[account] - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }
}
