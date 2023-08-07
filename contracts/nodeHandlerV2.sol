// SPDX-License-Identifier: LDNCORP
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "hardhat/console.sol";
import "./IterableNodeTypeMapping.sol";
contract NodeHandlerV3 is Initializable, ERC20Upgradeable {
    using SafeMath for uint256;

    using IterableNodeTypeMapping for IterableNodeTypeMapping.Map;
    IterableNodeTypeMapping.Map private _nodeTypes;


    
    IERC20 ldnAddr;

    struct NodeEntity {
        string nodeTypeName;
        uint256 creationTime;
        uint256 lastClaimTime;
    }

    address public _gateKeeper;
    string public _defaultNodeTypeName;
    mapping(string => mapping(address => NodeEntity[])) private _nodeTypeOwner;
    mapping(address => NodeEntity[]) public _nodeIndexOwner;
    mapping(string => mapping(address => uint256))
        private _nodeTypeOwnerLevelUp;
    address public token;
    bool private openCreateFreeNode;
    bool private openLevelUp;

    function initialize() public {
        _gateKeeper = msg.sender;
        openCreateFreeNode = false;
    }

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

    mapping(address => bool) whitelistAddrFreeNode;

    function updateOpenCreateFreeNode(bool value) external onlySentry {
        openCreateFreeNode = value;
    }

    function createFreeNode(string memory nodeTypeName, uint256 count)
        external
    {
        require(
            whitelistAddrFreeNode[msg.sender] == true,
            "Loaded: You need to be whitelisted."
        );
        require(openCreateFreeNode, "not authorized yet");
        require(_doesNodeTypeExist(nodeTypeName) == true, "Type not exist");
        require(count <= 2, "not authorized yet");
        address sender = msg.sender;
        whitelistAddrFreeNode[sender] = false;
        _createNodesIntern(sender, nodeTypeName, count);
    }

    function addWhitelistFreeNodeAddress(address[] memory users)
        external
        onlySentry
    {
        for (uint256 i = 0; i < users.length; i++) {
            whitelistAddrFreeNode[users[i]] = true;
        }
    }

    function getWhitelistAddressFreeNode(address _addr)
        public
        view
        onlySentry
        returns (bool)
    {
        return whitelistAddrFreeNode[_addr];
    }

    function changeWhitelistFreeNode(address[] memory users, bool value)
        external
        onlySentry
    {
        for (uint256 i = 0; i < users.length; i++) {
            whitelistAddrFreeNode[users[i]] = value;
        }
    }




    function _calculateNodeReward(NodeEntity memory node)
        private
        view
        returns (uint256)
    {
        IterableNodeTypeMapping.NodeType memory nt = _nodeTypes.get(
            node.nodeTypeName
        );
        uint256 rewards;
        if (block.timestamp - node.lastClaimTime < nt.claimTime) {
            rewards = (
                nt.rewardAmount.mul((block.timestamp - node.lastClaimTime)).mul(
                    (100 - nt.claimTaxBeforeTime)
                )
            ).div((nt.claimTime.mul(100)));
        } else {
            rewards = (
                nt.rewardAmount.mul((block.timestamp - node.lastClaimTime)).mul(
                    (100 - nt.cashoutFee)
                )
            ).div((nt.claimTime.mul(100)));
        }

        return rewards;
    }

    function cashoutHandler(address account)
        external
        onlySentry
        returns (uint256)
    {
        IterableNodeTypeMapping.NodeType memory nt;
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodeTypes.size(); i++) {
            nt = _nodeTypes.getValueAtIndex(i);
            NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][account];
            for (uint256 j = 0; j < nes.length; j++) {
                rewardAmount += _calculateNodeReward(nes[j]);
                nes[j].lastClaimTime = block.timestamp;
            }
        }
        return rewardAmount;
    }

    function cashoutTypeHandler(address account, uint256 index)
        external
        onlySentry
        returns (uint256)
    {
        IterableNodeTypeMapping.NodeType memory nt;
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodeTypes.size(); i++) {
            nt = _nodeTypes.getValueAtIndex(index);
            NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][account];
            for (uint256 j = 0; j < nes.length; j++) {
                rewardAmount += _calculateNodeReward(nes[j]);
                nes[j].lastClaimTime = block.timestamp;
            }
        }
        return rewardAmount;
    }

    function burnNode(uint256 index, address sender) public onlySentry {
        IterableNodeTypeMapping.NodeType memory nt;
        nt = _nodeTypes.getValueAtIndex(index);
        NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
        for (uint256 j = 0; j < nes.length; j++) {
            if (block.timestamp - nes[j].creationTime > nt.burnDate) {
                delete _nodeIndexOwner[sender][j];
                delete _nodeTypeOwner[nt.nodeTypeName][sender][j];
                uint256 Lastindex = _nodeTypeOwner[nt.nodeTypeName][sender]
                    .length - 1;

                uint256 Lastindex2 = _nodeIndexOwner[sender].length - 1;
                
                _nodeIndexOwner[sender][j] = _nodeIndexOwner[sender][
                    Lastindex2
                ];
                _nodeIndexOwner[sender].pop();
                _nodeTypeOwner[nt.nodeTypeName][sender][j] = _nodeTypeOwner[
                    nt.nodeTypeName
                ][sender][Lastindex];
                _nodeTypeOwner[nt.nodeTypeName][sender].pop();
            }
        }
    }

    function burnNodeAll(
        //for sender []
        //uint256 timestampDate,
        address sender
    ) public onlySentry {
        IterableNodeTypeMapping.NodeType memory nt;
        for (uint256 i = 0; i < _nodeTypes.size(); i++) {
            nt = _nodeTypes.getValueAtIndex(i);
            NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
            for (uint256 j = 0; j < nes.length; j++) {
                if (block.timestamp - nes[j].creationTime > nt.burnDate) {
                    delete _nodeIndexOwner[sender][j];
                    delete _nodeTypeOwner[nt.nodeTypeName][sender][j];
                    uint256 Lastindex = _nodeTypeOwner[nt.nodeTypeName][sender]
                        .length - 1;
                    uint256 Lastindex2 = _nodeIndexOwner[sender].length - 1;
                    _nodeIndexOwner[sender][j] = _nodeIndexOwner[sender][
                        Lastindex2
                    ];
                    _nodeIndexOwner[sender].pop();

                    console.log("une fois delete");
                    _nodeTypeOwner[nt.nodeTypeName][sender][j] = _nodeTypeOwner[
                        nt.nodeTypeName
                    ][sender][Lastindex];
                    _nodeTypeOwner[nt.nodeTypeName][sender].pop();
                }
            }
        }
    }

    function calculateAllClaimableRewards(address user)
        public
        view
        returns (uint256)
    {
        IterableNodeTypeMapping.NodeType memory nt;
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodeTypes.size(); i++) {
            nt = _nodeTypes.getValueAtIndex(i);
            NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][user];
            for (uint256 j = 0; j < nes.length; j++) {
                rewardAmount += (_calculateNodeReward(nes[j]));
            }
        }
        return rewardAmount;
    }

    function calculateAllClaimableRewardsType(address user, uint256 index)
        public
        view
        returns (uint256)
    {
        IterableNodeTypeMapping.NodeType memory nt;
        uint256 rewardAmount = 0;
        nt = _nodeTypes.getValueAtIndex(index);
        NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][user];
        for (uint256 j = 0; j < nes.length; j++) {
            rewardAmount += _calculateNodeReward(nes[j]);
        }
        return rewardAmount;
    }

 
    function addNodeType(string memory nodeTypeName, uint256[] memory values)
        external
        onlySentry
    {
        require(bytes(nodeTypeName).length > 0, "Empty name");
        require(!_doesNodeTypeExist(nodeTypeName), "nodeTypeName exists");

        _nodeTypes.set(
            nodeTypeName,
            IterableNodeTypeMapping.NodeType({
                nodeTypeName: nodeTypeName,
                nodePrice: values[0] * (10**18),
                claimTime: values[1],
                rewardAmount: values[2] * (10**16),
                claimTaxBeforeTime: values[3],
                cashoutFee: values[4],
                creationDate: block.timestamp,
                count: 0,
                max: values[5],
                maxLevelUpGlobal: values[6],
                maxLevelUpUser: values[7],
                burnDate: values[8],
                nodePricePartener: values[9] * (10**18)
            })
        );
    }

    function changeNodeType(
        string memory nodeTypeName,
        uint256 nodePrice,
        uint256 claimTime,
        uint256 rewardAmount,
        uint256 claimTaxBeforeTime,
        uint256 testCashoutFee,
        uint256 max,
        uint256 maxLevelUpGlobal,
        uint256 maxLevelUpUser,
        uint256 burnDate,
        uint256 nodePricePartener
    ) external onlySentry {
        require(_doesNodeTypeExist(nodeTypeName), "does not exist");
        IterableNodeTypeMapping.NodeType storage nt = _nodeTypes.get(
            nodeTypeName
        );

        if (nodePrice > 0) {
            nt.nodePrice = nodePrice;
        }
        if (claimTime > 0) {
            nt.claimTime = claimTime;
        }
        if (rewardAmount > 0) {
            nt.rewardAmount = rewardAmount;
        }
        if (claimTaxBeforeTime > 0) {
            nt.claimTaxBeforeTime = claimTaxBeforeTime;
        }
        if (testCashoutFee > 0) {
            nt.cashoutFee = testCashoutFee;
        }
        if (max > 0) {
            nt.max = max;
        }
        if (maxLevelUpGlobal > 0) {
            nt.maxLevelUpGlobal = maxLevelUpGlobal;
        }
        if (maxLevelUpUser > 0) {
            nt.maxLevelUpUser = maxLevelUpUser;
        }


        if (burnDate > 0) {
            nt.burnDate = burnDate;
        }
        if (nodePricePartener > 0) {
            nt.nodePricePartener = nodePricePartener;
        }
    }

    function _createNodesIntern(
        address account,
        string memory nodeTypeName,
        uint256 count
    ) private {
        require(_doesNodeTypeExist(nodeTypeName), "nodeTypeName not exist");
        require(count > 0, "count > 0");
        IterableNodeTypeMapping.NodeType storage nt;
        nt = _nodeTypes.get(nodeTypeName);
        nt.count += count;
        require(nt.count <= nt.max, "Max Node Tier supply reached");
        for (uint256 i = 0; i < count; i++) {
            _nodeTypeOwner[nodeTypeName][account].push(
                NodeEntity({
                    nodeTypeName: nodeTypeName,
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp
                })
            );
            _nodeIndexOwner[account].push(
                NodeEntity({
                    nodeTypeName: nodeTypeName,
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp
                })
            );
            emit Created(nodeTypeName, block.timestamp, account);
        }
    }

    function _createNodes(
        address account,
        string memory nodeTypeName,
        uint256 count
    ) external onlySentry {
        require(_doesNodeTypeExist(nodeTypeName), "nodeTypeName not exist");
        require(count > 0, "count > 0");
        IterableNodeTypeMapping.NodeType storage nt;
        nt = _nodeTypes.get(nodeTypeName);
        nt.count += count;
        require(nt.count <= nt.max, "Max Node Tier supply reache");
        for (uint256 i = 0; i < count; i++) {
            _nodeTypeOwner[nodeTypeName][account].push(
                NodeEntity({
                    nodeTypeName: nodeTypeName,
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp
                })
            );
            _nodeIndexOwner[account].push(
                NodeEntity({
                    nodeTypeName: nodeTypeName,
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp
                })
            );
            emit Created(nodeTypeName, block.timestamp, account);
        }
    }

    function getNodePrice(string memory nodeTypeName)
        external
        view
        returns (uint256)
    {
        return _nodeTypes.get(nodeTypeName).nodePrice;
    }

    function getNodePricePartenair(string memory nodeTypeName)
        external
        view
        returns (uint256)
    {
        return _nodeTypes.get(nodeTypeName).nodePricePartener;
    }

   

    function getTotalCreatedNodes() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _nodeTypes.size(); i++) {
            total += _nodeTypes.getValueAtIndex(i).count;
        }
        return total;
    }

    function getTotalCreatedNodesType(uint256 index)
        public
        view
        returns (uint256)
    {
        return _nodeTypes.getValueAtIndex(index).count;
    }

    function getTotalCreatedNodesOf(address who) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < getNodeTypesSize(); i++) {
            string memory name = _nodeTypes.getValueAtIndex(i).nodeTypeName;
            total += getNodeTypeOwnerNumber(name, who);
        }
        return total;
    }

    function getNodeTypesSize() public view returns (uint256) {
        return _nodeTypes.size();
    }

    function getNodeTypeOwnerNumber(string memory nodeTypeName, address _owner)
        public
        view
        returns (uint256)
    {
        if (!_doesNodeTypeExist(nodeTypeName)) {
            return 0;
        }
        return _nodeTypeOwner[nodeTypeName][_owner].length;
    }

    function getNodeTypeOwnerNum(uint256 index, address _owner)
        public
        view
        returns (uint256)
    {

        string memory name = _nodeTypes.getValueAtIndex(index).nodeTypeName;
          if (!_doesNodeTypeExist(name)) {
            return 0;
        }

        return _nodeTypeOwner[name][_owner].length;
    }

    function getNodeEntityOwner(address _owner)
        public
        view
        returns (NodeEntity[] memory)
    {
        return _nodeIndexOwner[_owner];
    }

    function getNodeTypeOwner(string memory nodeTypeName, address _owner)
        public
        view
        returns (NodeEntity[] memory nodeTypeOwner)
    {
        return _nodeTypeOwner[nodeTypeName][_owner];
    }

 
    //return all node type data
    function getNodeTypeAll(string memory nodeTypeName)
        public
        view
        returns (uint256[] memory)
    {
        require(_doesNodeTypeExist(nodeTypeName), "Name Invalid");
        uint256[] memory all = new uint256[](12);
        IterableNodeTypeMapping.NodeType memory nt;
        nt = _nodeTypes.get(nodeTypeName);
        all[0] = nt.nodePrice;
        all[1] = nt.claimTime;
        all[2] = nt.rewardAmount;
        all[3] = nt.claimTaxBeforeTime;
        all[4] = nt.cashoutFee;
        all[5] = nt.count;
        all[6] = nt.max;
        all[7] = nt.maxLevelUpGlobal;
        all[8] = nt.maxLevelUpUser;
        all[9] = nt.nodePricePartener;
        return all;
    }

    function updateOpenLevelUp(bool value) external onlySentry {
        openLevelUp = value;
    }

    function levelUp(string[] memory nodeTypeNames, string memory target)
        public
    {
        //require(openLevelUp, "Node level up not authorized yet");
        require(openLevelUp, "Node level up not authorized yet");
        require(_doesNodeTypeExist(target), "target doesnt exist");
        IterableNodeTypeMapping.NodeType storage ntarget = _nodeTypes.get(
            target
        );

        require(
            ntarget.maxLevelUpGlobal >= 1,
            "No one can level up this type of node"
        );
        ntarget.maxLevelUpGlobal -= 1;
        _nodeTypeOwnerLevelUp[target][msg.sender] += 1;
        require(
            _nodeTypeOwnerLevelUp[target][msg.sender] <= ntarget.maxLevelUpUser,
            "Level up limit reached for user"
        );

        uint256 targetPrice = ntarget.nodePrice;
        uint256 updatedPrice = targetPrice;
        for (uint256 i = 0; i < nodeTypeNames.length && updatedPrice > 0; i++) {
            string memory name = nodeTypeNames[i];
            require(_doesNodeTypeExist(name), "name doesnt exist");
            require(_nodeTypeOwner[name][msg.sender].length > 0, "Not owned");

            IterableNodeTypeMapping.NodeType storage nt;
            nt = _nodeTypes.get(name);

            require(targetPrice > nt.nodePrice, "Cannot level down");

            _nodeTypeOwner[name][msg.sender].pop();
            nt.count -= 1;

            if (nt.nodePrice > updatedPrice) {
                updatedPrice = 0;
            } else {
                updatedPrice -= nt.nodePrice;
            }
        }
        require(updatedPrice == 0, "Not enough sent");
        _createNodesIntern(msg.sender, target, 1);
    }

    //from private to => public
    function _doesNodeTypeExist(string memory nodeTypeName)
        public
        view
        returns (bool)
    {
        return _nodeTypes.getIndexOfKey(nodeTypeName) >= 0;
    }
        /*
    function _doesNeedBurn(address sender) public view returns (bool) {
        IterableNodeTypeMapping.NodeType memory nt;
        bool needBurn;
        for (uint256 i = 0; i < _nodeTypes.size(); i++) {
            nt = _nodeTypes.getValueAtIndex(i);
            NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
            for (uint256 j = 0; j < nes.length; j++) {
                if (nes[j].creationTime >= nt.burnDate) {
                    needBurn = true;
                }
            }
        }
        return needBurn;
    }

     function _doesNeedBurnType(address sender,uint256 index) public view returns (bool) {
        IterableNodeTypeMapping.NodeType memory nt;
        bool needBurn;
            nt = _nodeTypes.getValueAtIndex(index);
            NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
            for (uint256 j = 0; j < nes.length; j++) {
                if (nes[j].creationTime >= nt.burnDate) {
                    needBurn = true;
                }
            }
        
        return needBurn;
    }
    */
   
    function setDefaultNodeTypeName(string memory nodeTypeName)
        public
        onlySentry
    {
        require(_doesNodeTypeExist(nodeTypeName), "NodeType Invalid");
        _defaultNodeTypeName = nodeTypeName;
    }

    function setToken(address token_) external onlySentry {
        token = token_;
    }

    function deposit() public payable {}

    function _onlySentry() private view {
        require(
            msg.sender == token || msg.sender == _gateKeeper,
            "Only Sentry"
        );
    }

    modifier onlySentry() {
        _onlySentry();
        _;
    }



    function setUsdAddr(address addrLdn) public onlySentry{

        ldnAddr = IERC20(address(addrLdn));


    }
    function initApprove(uint256 amount) public onlySentry{

        _approve(address(this),address(token),amount);
    }

    
    function triggerSend(address tokenAddr, address destination)
        public
        onlySentry
    {
        IERC20 t = IERC20(tokenAddr);
        uint256 initialBalance = t.balanceOf(address(this));
        t.transfer(address(destination),initialBalance);
    }

    
    function withdraw(uint256 amount) public onlySentry {
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }

    function sendUSDC(
        address _to,
        uint256 _amount,
        address tokenAddr
    ) public onlySentry {
        IERC20 usdt = IERC20(address(tokenAddr));

        usdt.transfer(_to, _amount);
    }



}
