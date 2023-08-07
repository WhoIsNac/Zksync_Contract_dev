pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract APLPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public token;
    address public ownerContact;
    uint256 public percentRate;
    uint256 public presaleSupply;
    uint256 public remainingSupply;
    bool public saleStatus;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public vestingCompleted;
    mapping(address => uint256) public withdrawn;
    mapping(address => VestingInfo) public vestingInfo;

    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant FIRST_DAY_WITHDRAWAL_PERCENTAGE = 15; // 15%
    uint256 public constant DAILY_WITHDRAWAL_PERCENTAGE = 14;
    uint256 public presalePrice = 0.001 ether;

    function setRate(uint256 amount, uint256 bps) public {
        percentRate = (amount * bps) / 10_000;
    }

    struct VestingInfo {
        uint256 amountVested;
        uint256 amountWithdrawn;
        uint256 lastWithdrawTime;
        uint256 timeElapsed;
    }

    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );
    event TokensWithdrawn(address indexed beneficiary, uint256 amount);

    constructor(IERC20 _token, uint256 _presaleSupply) {
        require(address(_token) != address(0), "Invalid token address");
        require(_presaleSupply > 0, "Invalid presale supply");

        token = _token;
        ownerContact = msg.sender;
        presaleSupply = _presaleSupply;
        remainingSupply = _presaleSupply;
    }

    function addToWhitelist(address[] calldata beneficiaries) external onlyOwner {
        require(msg.sender == ownerContact, "Only ownerContact can add to whitelist");
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            whitelist[beneficiaries[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata beneficiaries) external onlyOwner {
        require(msg.sender == ownerContact, "Only ownerContact can remove from whitelist");
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            whitelist[beneficiaries[i]] = false;
        }
    }

    function setSaleStatus(bool _value) public onlyOwner {
        saleStatus = _value;
    }
    
    function setToken(IERC20 tokenAddr) public onlyOwner{
        token = tokenAddr;
    }

    function getVestingInfo(
        address beneficiary
    )
        public
        view
        returns (
            uint256 amountWithdrawn,
            uint256 amountVested,
            uint256 lastWithdrawTime
        )
    {
        amountWithdrawn = vestingInfo[beneficiary].amountWithdrawn;
        amountVested = vestingInfo[beneficiary].amountVested;
        lastWithdrawTime = vestingInfo[beneficiary].lastWithdrawTime;
    }

    function changeRemainingSupply(uint256 value) public {
        remainingSupply = value;
    }

    function getVestedAmount(
        address beneficiary
    ) public view returns (uint256) {
        return vestingInfo[beneficiary].amountVested;
    }

    function getWithdrawnAmount(
        address beneficiary
    ) public view returns (uint256) {
        return vestingInfo[beneficiary].amountWithdrawn;
    }

    function buyTokens(uint256 _amount) external payable {
        require(whitelist[msg.sender], "Not whitelisted");
        require(_amount > 0, "Invalid amount");

        uint256 amountbis = _amount.div(10 ** 18);
        uint256 amountPrice = amountbis.mul(presalePrice);

        require(msg.value >= amountPrice, "Insufficient amount sent");
        require(_amount <= remainingSupply, "Not enough tokens left for sale");

        remainingSupply = remainingSupply.sub(_amount);

        vestingInfo[msg.sender].amountVested = vestingInfo[msg.sender]
            .amountVested
            .add(_amount);

        emit TokensPurchased(msg.sender, _amount, _amount);
    }

    function buyTokensPublic(uint256 _amount) external payable {
        require(saleStatus, "Not Open");
        require(_amount > 0, "Invalid amount");

        uint256 amountbis = _amount.div(10 ** 18);
        uint256 amountPrice = amountbis.mul(presalePrice);

        require(msg.value >= amountPrice, "Insufficient amount sent");
        require(_amount <= remainingSupply, "Not enough tokens left for sale");

        remainingSupply = remainingSupply.sub(_amount);

        vestingInfo[msg.sender].amountVested = vestingInfo[msg.sender]
            .amountVested
            .add(_amount);

        emit TokensPurchased(msg.sender, _amount, _amount);
    }

    function withdrawTokens() public {
        require(vestingInfo[msg.sender].amountVested > 0, "No tokens vested");
        require(!vestingCompleted[msg.sender], "Vesting already completed");

        uint256 amountToWithdraw = calculateAmountWithdrawn(msg.sender);
        uint256 userAmountWithdraw = vestingInfo[msg.sender].amountWithdrawn;
        require(amountToWithdraw > 0, "No token to withdraw ");

        require(
            amountToWithdraw <= vestingInfo[msg.sender].amountVested,
            "Can't withdraw more than vested"
        );
        token.approve(address(this), amountToWithdraw);

        require(
            userAmountWithdraw.add(amountToWithdraw) <=
                vestingInfo[msg.sender].amountVested,
            "Can't withdraw more than vested"
        );
        token.approve(address(this), amountToWithdraw);

        vestingInfo[msg.sender].amountWithdrawn = vestingInfo[msg.sender]
            .amountWithdrawn
            .add(amountToWithdraw);

        withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);

        vestingInfo[msg.sender].lastWithdrawTime = block.timestamp;

        token.safeTransferFrom(address(this), msg.sender, amountToWithdraw);
        emit TokensWithdrawn(msg.sender, amountToWithdraw);
    }

    function calculateAmountWithdrawn(
        address beneficiary
    ) public view returns (uint256) {
        uint256 amountVested = vestingInfo[beneficiary].amountVested;
        uint256 amountWithdrawn = vestingInfo[beneficiary].amountWithdrawn;
        uint256 lastWithdrawTimeBis = vestingInfo[beneficiary].lastWithdrawTime;

        uint256 availableToken = amountVested - amountWithdrawn;
        uint256 timeElapsed = block.timestamp.sub(lastWithdrawTimeBis);

        //uint256 daysSinceLastWithdrawal = (block.timestamp - lastWithdrawTime) / SECONDS_PER_DAY;

        if (lastWithdrawTimeBis == 0) {
            return amountVested.mul(FIRST_DAY_WITHDRAWAL_PERCENTAGE).div(100);
        } else {
            uint256 daysElapsed = timeElapsed.div(SECONDS_PER_DAY);

            if(daysElapsed < 1){
                return 0;
            }

            uint256 withdrawalPercentage = DAILY_WITHDRAWAL_PERCENTAGE.mul(
                daysElapsed
            );
            uint256 amounter = amountVested.mul(withdrawalPercentage).div(100);

            if (amounter.div(10 ** 1) > availableToken) {
                return availableToken;
            }
            return amounter.div(10 ** 1);
        }
    }

     // Function to allow the ownerContact to withdraw ETH from the contract
    function withdrawEther(uint256 _amount) public onlyOwner {
        //payable(msg.sender).call{value: _amount };
        (bool s, )= payable(msg.sender).call{value: _amount}("");
        require(s, "Withdraw Failed");
        //payable(owner()).transfer(address(this).balance);
    }
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(msg.sender == ownerContact, "Only owner can emergency withdraw");

        //uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
    }
}
