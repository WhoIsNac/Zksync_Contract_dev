// SPDX-License-Identifier: LDNCORP
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";


//import "./lib.sol";
import "./nodeHandlerV2.sol";
//import "./nftHandler.sol";

//import "./LiquidityManager.sol";

//import "hardhat/console.sol";

contract Sigma is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    //using IterableNodeTypeMapping for IterableNodeTypeMapping.Map;
    using SafeMath for uint256;
    //ICronaSwapPair pairData;

    NodeHandlerV3 public nodeHandler;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _approvedERC;


    event Created(
        string nodeTypeName,
        uint256 creationTime,
        address indexed owner
    );
    event CashoutAll(
        uint256 rewardAmount,
        uint256 claimTime,
        address indexed owner
    );
    event BurnNode(uint256 TimeDelete, address indexed owner);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    IUniswapV2Router02 public uniswapV2Router;
    IERC20 USDCtoken;
    IERC20 token;

    //ILiquidityManager liquidityManager;
    address public uniV2Router;
    address public uniswapV2Pair;
    address public _gateKeeper;
    string public _defaultNodeTypeName;
    address public treasuryWall;
    address public distributionPool;
    address public poolHandler;
    address public teamWallet;
    address public privateSellContract;
    address public partenerShipWallet;
    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public futurFee;
    uint256 public totalFees;
    bool private swapping;
    bool private swapLiquify;
    uint256 public swapTokensAmount;
    bool private openCreate;
    bool private openCreatePresale;
    bool private openCashOut;
    address public usdcAddr;
    address public liquidityManagerAddr;
    uint256 public maxWPublicSale;

    uint256 public maxTx;
    mapping(address => bool) public _isSuper;

    function initialize(
        address[] memory addresses,
        uint256[] memory balances,
        uint256[] memory fees,
        uint256 swapAmount,
        address _uniV2Router
    ) public initializer {
        __ERC20_init("test Token", "TT");
        __Ownable_init();
        _gateKeeper = msg.sender;
        treasuryWall = addresses[0];
        distributionPool = addresses[1];
        poolHandler = addresses[2];
        privateSellContract = addresses[3];
        partenerShipWallet = addresses[4];
        uniV2Router = _uniV2Router;
        require(
            treasuryWall != address(0) &&
                distributionPool != address(0) &&
                poolHandler != address(0) &&
                partenerShipWallet != address(0),
            "REWARD,POOL&ROUTER ADDRESS CANNOT BE ZERO"
        );
        require(
            fees[0] != 0 && fees[1] != 0 && fees[2] != 0,
            "Fees = 0"
        );
        futurFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
       
        totalFees = rewardsFee + liquidityPoolFee + futurFee;
        require(
            addresses.length > 0 && balances.length > 0,
            "array length > zero"
        );
        require(addresses.length == balances.length, "arrays length mismatch");
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], balances[i] * (10**18));
            _isSuper[addresses[i]] = true;
        }
        require(totalSupply() == 1000000e18, "must equal 1 million");
        require(swapAmount > 0, "amount incorrect");
        swapTokensAmount = swapAmount * (10**18);
        swapLiquify = true;

        /*
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniV2Router);
         address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
         .createPair(address(this), address(USDCtoken));
         uniswapV2Router = _uniswapV2Router;
         uniswapV2Pair = _uniswapV2Pair;         
         */
    }

    function setNodeHandler(address nodHandler) external onlyOwner {
        nodeHandler = NodeHandlerV3(nodHandler);
    }

 

    receive() external payable {}


    



    /*
    // ====== SWAP Handle ====== 
    IUniswapV2Router01 public uniswapV2RouterBIS;

    //**        UNISWAP / SET USDC PART */
    function updateUniswapRouter(address newAddress) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newAddress);
       // IUniswapV2Router01 _uniswapV2RouterBIS = IUniswapV2Router01(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
    }



    
    // ====== ADD LP PART ======
     function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            poolHandler,
            block.timestamp
        );
    }

    function addLiquidityInitial(uint256 tokenAmount, uint256 ethAmount)
        public
        onlyOwner
    {
        //uint256 amount = ethAmount;
        _approve(address(this), address(uniswapV2Router), tokenAmount);


        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            poolHandler,
            block.timestamp
        );
    }
    
    
    function swapTokensForEth(uint256 tokenAmount) public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    // ====== SWAP MANAGMENT  ======
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "0 addr");
        require(to != address(0), "0 addr");
          require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted addr"
        );
    
        super._transfer(from, to, amount);
    }

    
    // ====== CREATE NODE PART ======

    function createNodeWithTokens(string memory nodeTypeName, uint256 count)
        public
        nonReentrant
    {
        require(openCreate, "not authorized yet");
        require(
            nodeHandler._doesNodeTypeExist(nodeTypeName) == true,
            "NodeType not exist"
        );
        address sender = msg.sender;
        require(
            sender != treasuryWall && sender != distributionPool,
            "futur and rewardsPool cannot create"
        );
        uint256 nodePrice = nodeHandler.getNodePrice(nodeTypeName) * count;
        require(balanceOf(sender) >= nodePrice, "Balance too low");
        super._transfer(sender, address(this), nodePrice);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && swapLiquify && !swapping && sender != _gateKeeper) {
            swapping = true;

            uint256 futurTokens = contractTokenBalance.mul(futurFee).div(100);
            swapAndSendToFee(treasuryWall, futurTokens); 

            uint256 rewardsPoolTokens = contractTokenBalance
                .mul(rewardsFee)
                .div(100);
            
            super._transfer(address(this),distributionPool, rewardsPoolTokens);
            
            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(
                100
            );
            swapAndLiquify(swapTokens); 

            swapping = false;
        }
        nodeHandler._createNodes(sender, nodeTypeName, count);
    }

   

    function createNodePresale(string memory nodeTypeName, uint256 count)
        public
        payable
        nonReentrant
    {
        require(openCreatePresale, "not authorized yet");
        require(nodeHandler.getTotalCreatedNodesOf(msg.sender) < maxWPublicSale && count < maxWPublicSale,"Max per wallet");
        require(
            nodeHandler._doesNodeTypeExist(nodeTypeName) == true,
            "NodeType not exist"
        );
        uint256 nodePrice = (
            nodeHandler.getNodePrice(nodeTypeName).mul(count)
        ) / 1 ether;
        require(
            msg.value >= nodePrice * (1 ether),
            "Need to send exact amount of wei"
        );

        address sender = msg.sender;

        nodeHandler._createNodes(sender, nodeTypeName, count);
    }

    function createNodeWithSpecToken(
        string memory nodeTypeName,
        uint256 count,
        address tokenAddr
    ) public nonReentrant {
        require(openCreate, "not authorized yet");
        require(_approvedERC[tokenAddr],"erc not auth");
        require(
            nodeHandler._doesNodeTypeExist(nodeTypeName) == true,
            "NodeType not exist"
        );
        require(tokenAddr != address(0), "Token address not exist");
        address sender = msg.sender;
        token = IERC20(tokenAddr);
        uint256 nodePrice = nodeHandler.getNodePricePartenair(nodeTypeName) *
            count;
        require(token.balanceOf(sender) >= nodePrice, "Balance too low");

        token.transferFrom(sender, address(this), nodePrice);
        nodeHandler._createNodes(sender, nodeTypeName, count);
    }

    

       // ====== CALCULE HANDLE PART ======


        // ====== CASHOUT NODE PART ======




    function cashoutAll() public {
        require(openCashOut, "not authorized yet");
        address sender = msg.sender;
        uint256 rewardAmount = 0;
        rewardAmount = nodeHandler.cashoutHandler(sender);
        require(rewardAmount > 0, "Nothing..");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapLiquify && swapAmountOk) {
            uint256 futurTokens = contractTokenBalance.mul(futurFee).div(100);
            swapAndSendToFee(treasuryWall, futurTokens);
        }
        super._transfer(distributionPool, sender, rewardAmount);
        emit CashoutAll(rewardAmount, block.timestamp, sender);
        /*
            if(nodeHandler._doesNeedBurn(sender) == true){
                for (uint256 i = 0; i < nodeHandler.getTotalCreatedNodesOf(sender);i++) {
                    nodeHandler.burnNodeAll(sender);
                    emit BurnNode(block.timestamp, sender);
                }
                nodeHandler.burnNodeAll(sender);

        } */

    }

    function cashoutAllType(uint256 index) public {
        require(openCashOut, "not authorized yet");
        address sender = msg.sender;
        uint256 rewardAmount = 0;
        rewardAmount = nodeHandler.cashoutTypeHandler(sender, index);
        require(rewardAmount > 0, "Nothing..");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapLiquify && swapAmountOk) {
            uint256 futurTokens = contractTokenBalance.mul(futurFee).div(100);
            swapAndSendToFee(treasuryWall, futurTokens);
        }
        super._transfer(distributionPool, sender, rewardAmount);
        emit CashoutAll(rewardAmount, block.timestamp, sender);
        /*
        if(nodeHandler._doesNeedBurnType(sender,index) == true){

        for (uint256 i = 0; i < nodeHandler.getNodeTypeOwnerNum(index,sender);i++) {
            nodeHandler.burnNode(index, sender);
            emit BurnNode(block.timestamp, sender);
        }
        nodeHandler.burnNode(index, sender);
        }
        */

 
    }

        // ====== GET & SET  ======


    function getTotalCreatedNodes() public view returns (uint256) {
        return nodeHandler.getTotalCreatedNodes();
    }

    function getTotalCreatedNodesType(uint256 index)
        public
        view
        returns (uint256)
    {
        return nodeHandler.getTotalCreatedNodesType(index);
    }

    function getTotalCreatedNodesOf(address who) public view returns (uint256) {
        return nodeHandler.getTotalCreatedNodesOf(who);
    }

    function getNodeTypesSize() public view returns (uint256) {
        return nodeHandler.getNodeTypesSize();
    }

    function getNodeTypeOwnerNumber(string memory nodeTypeName, address _owner)
        public
        view
        returns (uint256)
    {
        return nodeHandler.getNodeTypeOwnerNumber(nodeTypeName, _owner);
    }

    //return all node type data
    function getNodeTypeAll(string memory nodeTypeName)
        public
        view
        returns (uint256[] memory)
    {
        return nodeHandler.getNodeTypeAll(nodeTypeName);
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        treasuryWall = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee + liquidityPoolFee + futurFee;
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee + liquidityPoolFee + futurFee;
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee + liquidityPoolFee + futurFee;
    }

    function updateGateKeeper(address _new) external onlyOwner {
        _gateKeeper = _new;
    }

    function updateOpenCreate(bool value) external onlyOwner {
        openCreate = value;
    }

    function updateOpenCreatePresale(bool value) external onlyOwner {
        openCreatePresale = value;
    }



    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function updateOpenCashOut(bool newVal) public onlyOwner {
        openCashOut = newVal;
    }
 

    function setMaxPresale(uint256 amount) public onlyOwner{
      maxWPublicSale = amount;
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function approvedERC20(address account, bool value)
        external
        onlyOwner
    {
        _approvedERC[account] = value;
    }

    function deposit() public payable {}

    function deposeLDN(uint256 amount) public {
        super._transfer(msg.sender, address(this), amount);
    }

    function withdrawLDN(uint256 amount) public onlyOwner {
        super._transfer(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        //address payable to = payable(msg.sender); 
        //to.transfer(amount);
        (bool s, )= payable(msg.sender).call{value: amount}("");
        require(s, "Withdraw Failed");
    }

    function sendERC20(
        address _to,
        uint256 _amount,
        address tokenAddr
    ) public onlyOwner {
        IERC20 usdt = IERC20(address(tokenAddr));

        usdt.transfer(_to, _amount);
    }

    

    fallback() external payable {}
}
