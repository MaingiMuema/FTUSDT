// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITRC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IPriceOracle.sol";
import "./ICollateralManager.sol";
import "./IGovernance.sol";
import "./InsurancePool.sol";
import "./IFlashLoanReceiver.sol";

/**
 * @title Flash USDT Stablecoin
 * @dev Implementation of a collateralized stablecoin with enhanced security and governance
 */
contract FTUSDT is ITRC20, Ownable, Pausable {
    // Existing declarations...
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
    
    // Loan system parameters
    uint256 public constant MIN_LOAN_TERM = 1 days;
    uint256 public constant MAX_LOAN_TERM = 365 days;
    uint256 public constant BASE_INTEREST_RATE = 500; // 5% annual rate in basis points
    uint256 public constant INTEREST_RATE_MULTIPLIER = 100; // For risk adjustment
    uint256 public constant LATE_PAYMENT_PENALTY = 1000; // 10% penalty in basis points
    
    struct Loan {
        uint256 principal;
        uint256 collateralAmount;
        uint256 interestRate;
        uint256 term;
        uint256 startTime;
        uint256 lastInterestPayment;
        uint256 totalRepaid;
        bool active;
        LoanStatus status;
    }
    
    enum LoanStatus { PENDING, ACTIVE, REPAID, DEFAULTED, LIQUIDATED }
    
    mapping(address => Loan[]) public userLoans;
    mapping(address => uint256) public activeLoanCount;
    
    // Flash loan parameters
    uint256 public constant FLASH_LOAN_FEE = 9; // 0.09% fee
    
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
    event LoanCreated(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 principal,
        uint256 collateralAmount,
        uint256 interestRate,
        uint256 term
    );
    event LoanRepayment(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 amount,
        uint256 remainingBalance
    );
    event LoanLiquidated(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 collateralAmount,
        uint256 debtAmount
    );
    event LoanCompleted(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 totalRepaid
    );
    event FlashLoan(
        address indexed receiver,
        uint256 amount,
        uint256 fee
    );

    // New declarations for enhanced security
    bool private _notEntered;
    bool public emergencyMode;
    address public emergencyAdmin;
    InsurancePool public insurancePool;
    IGovernance public governance;
    
    struct MarketParameters {
        uint256 collateralRatio;
        uint256 liquidationThreshold;
        uint256 flashLoanFee;
        uint256 pegTolerance;
        uint256 maxLoanTerm;
        uint256 minLoanTerm;
        uint256 baseInterestRate;
        uint256 stabilityFee;
    }
    
    MarketParameters public parameters;
    
    // Circuit breaker thresholds
    uint256 public constant PRICE_CHANGE_THRESHOLD = 20; // 20% price change
    uint256 public constant VOLUME_SPIKE_THRESHOLD = 1000000 * 10**6; // 1M FTUSDT
    uint256 public constant LIQUIDATION_SPIKE_THRESHOLD = 100; // 100 liquidations per hour
    
    // Tracking variables
    uint256 public hourlyVolume;
    uint256 public hourlyLiquidations;
    uint256 public lastVolumeReset;
    uint256 public lastPrice;
    
    event EmergencyModeEnabled(address indexed trigger);
    event EmergencyModeDisabled(address indexed trigger);
    event CircuitBreakerTriggered(string reason);
    event ParametersUpdated(bytes32 indexed parameter, uint256 newValue);
    event MarketWarning(string warning);

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    modifier validateReceiver(address receiver) {
        require(receiver != address(this), "Self-interaction not allowed");
        require(receiver.code.length > 0, "EOA not allowed");
        _;
    }
    
    modifier onlyEmergencyAdmin() {
        require(msg.sender == emergencyAdmin || msg.sender == owner(), "Not emergency admin");
        _;
    }
    
    constructor(
        uint256 initialSupply,
        address _priceOracle,
        address _collateralManager,
        address _governance,
        address _insurancePool
    ) {
        _notEntered = true;
        emergencyMode = false;
        emergencyAdmin = msg.sender;
        
        // Initialize market parameters
        parameters = MarketParameters({
            collateralRatio: 150,
            liquidationThreshold: 120,
            flashLoanFee: 9,
            pegTolerance: 1 * 10**16,
            maxLoanTerm: 365 days,
            minLoanTerm: 1 days,
            baseInterestRate: 500,
            stabilityFee: 5
        });
        
        // Initialize contracts
        _mint(msg.sender, initialSupply * 10**_decimals);
        feeCollector = msg.sender;
        _approvers[msg.sender] = true;
        priceOracle = IPriceOracle(_priceOracle);
        collateralManager = ICollateralManager(_collateralManager);
        governance = IGovernance(_governance);
        insurancePool = InsurancePool(_insurancePool);
        
        lastVolumeReset = block.timestamp;
        lastPrice = priceOracle.getPrice();
        
        emit ApproverAdded(msg.sender);
    }

    /**
     * @dev Enhanced flash loan with additional security measures
     */
    function flashLoan(
        address receiver,
        uint256 amount,
        bytes calldata params
    ) external nonReentrant whenNotPaused validateReceiver(receiver) {
        require(!emergencyMode, "Emergency mode: Flash loans disabled");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= _totalSupply, "Amount too large");
        
        // Update volume tracking
        _updateHourlyVolume(amount);
        
        uint256 fee = (amount * parameters.flashLoanFee) / 10000;
        uint256 amountToRepay = amount + fee;
        
        // Record state before flash loan
        uint256 balanceBefore = _totalSupply;
        bytes32 hashBefore = _getStateHash();
        
        // Transfer funds to receiver
        _mint(receiver, amount);
        
        // Execute receiver's logic with timeout
        try IFlashLoanReceiver(receiver).executeOperation(amount, fee, params) returns (bool success) {
            require(success, "Flash loan execution failed");
        } catch {
            revert("Flash loan execution reverted");
        }
        
        // Verify state
        require(_getStateHash() == hashBefore, "State manipulation detected");
        
        // Burn repaid amount
        require(_balances[receiver] >= amountToRepay, "Insufficient repayment");
        _burn(receiver, amountToRepay);
        
        // Final verification
        require(_totalSupply == balanceBefore, "Flash loan not repaid");
        
        emit FlashLoan(receiver, amount, fee);
    }

    /**
     * @dev Emergency controls
     */
    function enableEmergencyMode() external onlyEmergencyAdmin {
        emergencyMode = true;
        _pause();
        emit EmergencyModeEnabled(msg.sender);
    }
    
    function disableEmergencyMode() external onlyEmergencyAdmin {
        require(_checkMarketConditions(), "Market conditions not stable");
        emergencyMode = false;
        _unpause();
        emit EmergencyModeDisabled(msg.sender);
    }
    
    /**
     * @dev Governance functions
     */
    function updateParameters(bytes32 parameter, uint256 newValue) external {
        require(msg.sender == address(governance), "Only governance can update");
        
        if (parameter == "collateralRatio") {
            require(newValue >= 120 && newValue <= 200, "Invalid collateral ratio");
            parameters.collateralRatio = newValue;
        } else if (parameter == "liquidationThreshold") {
            require(newValue >= 110 && newValue <= 150, "Invalid liquidation threshold");
            parameters.liquidationThreshold = newValue;
        } // Add other parameter updates...
        
        emit ParametersUpdated(parameter, newValue);
    }
    
    /**
     * @dev Enhanced market monitoring
     */
    function _updateHourlyVolume(uint256 amount) internal {
        if (block.timestamp >= lastVolumeReset + 1 hours) {
            hourlyVolume = 0;
            hourlyLiquidations = 0;
            lastVolumeReset = block.timestamp;
        }
        
        hourlyVolume += amount;
        if (hourlyVolume >= VOLUME_SPIKE_THRESHOLD) {
            emit CircuitBreakerTriggered("Volume spike detected");
            enableEmergencyMode();
        }
    }
    
    function _checkMarketConditions() internal view returns (bool) {
        uint256 currentPrice = priceOracle.getPrice();
        uint256 priceChange = _calculateDeviation(currentPrice, lastPrice);
        
        if (priceChange >= PRICE_CHANGE_THRESHOLD) return false;
        if (hourlyVolume >= VOLUME_SPIKE_THRESHOLD) return false;
        if (hourlyLiquidations >= LIQUIDATION_SPIKE_THRESHOLD) return false;
        
        return true;
    }
    
    function _getStateHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_totalSupply, address(this).balance));
    }
    
    function _calculateDeviation(uint256 value1, uint256 value2) internal pure returns (uint256) {
        if (value1 > value2) {
            return ((value1 - value2) * 100) / value2;
        }
        return ((value2 - value1) * 100) / value1;
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

    /**
     * @dev Creates a new loan with collateral
     * @param principal Amount to borrow
     * @param term Loan duration in seconds
     * @return loanId The ID of the created loan
     */
    function createLoan(
        uint256 principal,
        uint256 term
    ) external whenNotPaused returns (uint256) {
        require(principal >= MIN_MINT_AMOUNT, "FTUSDT: Principal too low");
        require(principal <= MAX_MINT_AMOUNT, "FTUSDT: Principal too high");
        require(term >= MIN_LOAN_TERM, "FTUSDT: Term too short");
        require(term <= MAX_LOAN_TERM, "FTUSDT: Term too long");
        require(activeLoanCount[msg.sender] < 5, "FTUSDT: Too many active loans");

        uint256 requiredCollateral = calculateRequiredCollateral(principal);
        require(
            collateralPositions[msg.sender].collateralAmount >= requiredCollateral,
            "FTUSDT: Insufficient collateral"
        );

        uint256 interestRate = calculateInterestRate(
            principal,
            requiredCollateral,
            term
        );

        Loan memory newLoan = Loan({
            principal: principal,
            collateralAmount: requiredCollateral,
            interestRate: interestRate,
            term: term,
            startTime: block.timestamp,
            lastInterestPayment: block.timestamp,
            totalRepaid: 0,
            active: true,
            status: LoanStatus.ACTIVE
        });

        uint256 loanId = userLoans[msg.sender].length;
        userLoans[msg.sender].push(newLoan);
        activeLoanCount[msg.sender]++;

        // Lock collateral
        collateralPositions[msg.sender].collateralAmount -= requiredCollateral;
        
        // Mint and transfer the loan amount
        _mint(msg.sender, principal);

        emit LoanCreated(
            msg.sender,
            loanId,
            principal,
            requiredCollateral,
            interestRate,
            term
        );

        return loanId;
    }

    /**
     * @dev Calculates the interest rate based on loan parameters
     */
    function calculateInterestRate(
        uint256 principal,
        uint256 collateral,
        uint256 term
    ) public view returns (uint256) {
        uint256 collateralRatio = (collateral * 100) / principal;
        uint256 riskAdjustment = collateralRatio >= 200
            ? 0
            : ((200 - collateralRatio) * INTEREST_RATE_MULTIPLIER) / 100;
        
        uint256 termAdjustment = (term * INTEREST_RATE_MULTIPLIER) / MAX_LOAN_TERM;
        
        return BASE_INTEREST_RATE + riskAdjustment + termAdjustment;
    }

    /**
     * @dev Calculates required collateral for a loan
     */
    function calculateRequiredCollateral(uint256 principal) public view returns (uint256) {
        return (principal * MINIMUM_COLLATERAL_RATIO) / 100;
    }

    /**
     * @dev Make a repayment towards a loan
     */
    function repayLoan(uint256 loanId, uint256 amount) external whenNotPaused {
        require(loanId < userLoans[msg.sender].length, "FTUSDT: Invalid loan ID");
        Loan storage loan = userLoans[msg.sender][loanId];
        require(loan.active, "FTUSDT: Loan not active");
        require(amount > 0, "FTUSDT: Invalid amount");
        require(_balances[msg.sender] >= amount, "FTUSDT: Insufficient balance");

        uint256 interest = calculateInterestDue(loan);
        uint256 totalDue = loan.principal + interest;
        require(loan.totalRepaid + amount <= totalDue, "FTUSDT: Overpayment");

        // Process payment
        _burn(msg.sender, amount);
        loan.totalRepaid += amount;
        loan.lastInterestPayment = block.timestamp;

        // Check if loan is fully repaid
        if (loan.totalRepaid >= totalDue) {
            completeLoan(msg.sender, loanId);
        }

        emit LoanRepayment(msg.sender, loanId, amount, totalDue - loan.totalRepaid);
    }

    /**
     * @dev Calculates interest due for a loan
     */
    function calculateInterestDue(Loan storage loan) internal view returns (uint256) {
        if (!loan.active) return 0;
        
        uint256 timeElapsed = block.timestamp - loan.lastInterestPayment;
        uint256 annualInterest = (loan.principal * loan.interestRate) / 10000;
        uint256 interest = (annualInterest * timeElapsed) / 365 days;
        
        // Add late payment penalty if applicable
        if (block.timestamp > loan.startTime + loan.term) {
            uint256 overduePeriod = block.timestamp - (loan.startTime + loan.term);
            uint256 penaltyInterest = (loan.principal * LATE_PAYMENT_PENALTY * overduePeriod) / (10000 * 365 days);
            interest += penaltyInterest;
        }
        
        return interest;
    }

    /**
     * @dev Completes a loan and returns collateral
     */
    function completeLoan(address borrower, uint256 loanId) internal {
        Loan storage loan = userLoans[borrower][loanId];
        require(loan.active, "FTUSDT: Loan not active");

        loan.active = false;
        loan.status = LoanStatus.REPAID;
        activeLoanCount[borrower]--;

        // Return collateral
        collateralPositions[borrower].collateralAmount += loan.collateralAmount;

        emit LoanCompleted(borrower, loanId, loan.totalRepaid);
    }

    /**
     * @dev Liquidates a loan if it's eligible
     */
    function liquidateLoan(address borrower, uint256 loanId) external whenNotPaused {
        require(loanId < userLoans[borrower].length, "FTUSDT: Invalid loan ID");
        Loan storage loan = userLoans[borrower][loanId];
        require(loan.active, "FTUSDT: Loan not active");

        uint256 totalDue = loan.principal + calculateInterestDue(loan);
        bool isOverdue = block.timestamp > loan.startTime + loan.term;
        uint256 collateralValue = getCollateralValue(loan.collateralAmount);
        bool isUndercollateralized = collateralValue < totalDue;

        require(
            isOverdue || isUndercollateralized,
            "FTUSDT: Loan not eligible for liquidation"
        );

        // Process liquidation
        loan.active = false;
        loan.status = LoanStatus.LIQUIDATED;
        activeLoanCount[borrower]--;

        // Transfer collateral to liquidator with penalty
        uint256 liquidationAmount = (loan.collateralAmount * (100 - LIQUIDATION_PENALTY)) / 100;
        collateralPositions[msg.sender].collateralAmount += liquidationAmount;

        emit LoanLiquidated(borrower, loanId, loan.collateralAmount, totalDue);
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
