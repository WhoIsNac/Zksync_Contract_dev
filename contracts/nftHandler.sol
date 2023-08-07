
// SPDX-License-Identifier: LDNCORP
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./nodeHandlerV2.sol";


contract NftHandlerV1 is
    Initializable,ReentrancyGuardUpgradeable{




struct NftEntity {
        uint256[] id;
        bool active;
        string nodeTypeName;
        uint256 rewardBoost;
        uint256 timeBoost;
        uint256 feesReduce;
        uint256 option;
        address nftAddr;
        bool typeReward;
        bool typeBoost;
        bool typeReduce;
    }

    struct NftInfo {
        string nftName; ///gold reward
        uint256[] nftId; //["1","2","4" 100 245]
        uint256 rewardBoost;
        uint256 timeBoost;
        uint256 feesReduce;
    }

    struct NftIdtoReward {
        uint256 typeNft;
        uint256 rewardBoost;
        uint256 timeBoost;
        uint256 feesReduce;
        address nftAddr;
    }


    address public _gateKeeper;
    address public token;


    NodeHandlerV3 public nodeHandler;

    mapping(uint256 => NftIdtoReward) public nftIdToReward;
    mapping(string => mapping(address => NftEntity)) public _attachedNft2;
    mapping(string => mapping(uint256 => NftInfo[])) public nftInfo;
    mapping(uint256 => NftIdtoReward) public partenerToReward;

     function initialize() public {
        _gateKeeper = msg.sender;
    }



    function setGatekeeper() public onlySentry{
        _gateKeeper = msg.sender;
    }
    function setNodeHandler(address nodHandler) external onlySentry {
        nodeHandler = NodeHandlerV3(nodHandler);
    }

    function setPartenairNftData(
        uint256 id,
        uint256 rewardBoost,
        uint256 timeBoost,
        uint256 feesReduce,
        address nft
    ) public onlySentry {
        partenerToReward[id].typeNft = id;
        partenerToReward[id].rewardBoost = rewardBoost;
        partenerToReward[id].timeBoost = timeBoost;
        partenerToReward[id].feesReduce = feesReduce;
        partenerToReward[id].nftAddr = nft;
    }

    function setNFTData(NftIdtoReward[] memory _nftInfo, uint256 nbNft) public onlySentry{
        for (uint256 i = 0; i < nbNft; i++) {
            nftIdToReward[i + 1].typeNft = _nftInfo[i].typeNft;
            nftIdToReward[i + 1].rewardBoost = _nftInfo[i].rewardBoost;
            nftIdToReward[i + 1].timeBoost = _nftInfo[i].timeBoost;
            nftIdToReward[i + 1].feesReduce = _nftInfo[i].feesReduce;
            nftIdToReward[i + 1].nftAddr = _nftInfo[i].nftAddr;   
        }
    }

    function getNFTDATA(uint256 id) public view returns (NftIdtoReward memory) {
        return nftIdToReward[id];
    }

     function getPartnairData(uint256 id) public view returns (NftIdtoReward memory) {
        return partenerToReward[id];
    }
    
    
    

      function addNft(
        address sender,
        ERC721 _nftAddr,
        uint256 nftId,
        string memory nodeTypeName
    ) external
        onlySentry nonReentrant {
        require(_nftAddr.balanceOf(sender) > 0, "no nft owned");
        require(_nftAddr.ownerOf(nftId) == sender, "not the owner");

        if (!_attachedNft2[nodeTypeName][sender].active) {
            NftIdtoReward memory nes = nftIdToReward[nftId];
            bool typ1 = false;
            bool typ2 = false;
            bool typ3 = false;

            if (nes.typeNft == 0) {
                typ1 = true;
            } else if (nes.typeNft == 1) {
                typ2 = true;
            } else if (nes.typeNft == 2) {
                typ3 = true;
            }

            uint256[] memory tab1 = new uint256[](1);
            tab1[0] = nftId;
            //tab1.push(nftId);
            _attachedNft2[nodeTypeName][sender] = (
                NftEntity({
                    id: tab1,
                    active: true,
                    nodeTypeName: nodeTypeName,
                    timeBoost: nes.timeBoost,
                    rewardBoost: nes.rewardBoost * (10**16),
                    feesReduce: nes.feesReduce,
                    option: 0,
                    nftAddr: address(_nftAddr),
                    typeReward: typ1,
                    typeBoost: typ2,
                    typeReduce: typ3
                })
            );
        } else {
            NftIdtoReward memory nftRewardmap = nftIdToReward[nftId];
            bool canSet = false;

            NftEntity storage nftmap = _attachedNft2[nodeTypeName][sender];
            bool tmp1 = nftmap.typeReward;
            bool tmp2 = nftmap.typeBoost;
            bool tmp3 = nftmap.typeReduce;

            for (uint256 i = 0; i < nftmap.id.length; i++) {
                if (nftId != nftmap.id[i]) {
                    canSet = true;
                }
            }

            require(canSet, "Nft already attached");
            if (nftRewardmap.typeNft == 0) {
                require(!tmp1, "reward already set");
            } else if (nftRewardmap.typeNft == 1) {
                require(!tmp2, "time already set");
            } else if (nftRewardmap.typeNft == 2) {
                require(!tmp3, "feesR already set");
            }

            if (nftRewardmap.typeNft == 0) {
                nftmap.rewardBoost = nftRewardmap.rewardBoost * (10**16);
                nftmap.typeReward = true;
            } else if (nftRewardmap.typeNft == 1) {
                nftmap.timeBoost = nftRewardmap.timeBoost;
                nftmap.typeBoost = true;
            } else if (nftRewardmap.typeNft == 2) {
                nftmap.feesReduce = nftRewardmap.feesReduce;
                nftmap.typeReduce = true;
            }

            nftmap.id.push(nftId);
        }
    }

    function addNftPartener(
        address sender,
        ERC721 _nftAddr,
        uint256 nftId,
        uint256 idPartener,
        string memory nodeTypeName
    ) external
        onlySentry nonReentrant {
        // require( nodeHandler._doesNodeTypeExist(nodeTypeName) == true,"NodeType not exist");
        //require(openNft, "not authorized yet");
        require(
            partenerToReward[idPartener].nftAddr == address(_nftAddr),
            "you are using the wrong addr"
        );
        require(_nftAddr.balanceOf(sender) > 0, "no nft owned");
        require(_nftAddr.ownerOf(nftId) == sender, "not the owner");
        require(
            _attachedNft2[nodeTypeName][sender].id.length < 2,
            "no nft allowed"
        );

        if (!_attachedNft2[nodeTypeName][sender].active) {
            bool type1;
            bool type2;
            bool type3;

            if (partenerToReward[idPartener].rewardBoost > 0) {
                type1 = true;
            } else if (partenerToReward[idPartener].feesReduce > 0) {
                type2 = true;
            } else if (partenerToReward[idPartener].timeBoost > 0) {
                type3 = true;
            }

            partenerToReward[idPartener];

            uint256[] memory tab1 = new uint256[](1);
            tab1[0] = nftId;
            //tab1.push(nftId);
            _attachedNft2[nodeTypeName][sender] = (
                NftEntity({
                    id: tab1,
                    active: true,
                    nodeTypeName: nodeTypeName,
                    timeBoost: partenerToReward[idPartener].timeBoost,
                    rewardBoost: partenerToReward[idPartener].rewardBoost *
                        (10**16),
                    feesReduce: partenerToReward[idPartener].feesReduce,
                    option: 0,
                    nftAddr: address(_nftAddr),
                    typeReward: type1,
                    typeBoost: type2,
                    typeReduce: type3
                })
            );
        } else {
            NftIdtoReward memory nftRewardmap = partenerToReward[idPartener];

            bool canSet = false;

            NftEntity storage nftmap = _attachedNft2[nodeTypeName][sender];
            bool tmp1 = nftmap.typeReward;
            bool tmp2 = nftmap.typeBoost;
            bool tmp3 = nftmap.typeReduce;

            for (uint256 i = 0; i < nftmap.id.length; i++) {
                if (nftId != nftmap.id[i]) {
                    canSet = true;
                }
            }

            require(canSet, "Nft already attached");

            if (nftRewardmap.rewardBoost > 0) {
                require(!tmp1, "reward already set");
            } else if (nftRewardmap.feesReduce > 0) {
                require(!tmp2, "time already set");
            } else if (nftRewardmap.timeBoost > 0) {
                require(!tmp3, "feesR already set");
            }

            if (nftRewardmap.feesReduce > 0) {
                nftmap.typeBoost = true;
                nftmap.feesReduce = nftRewardmap.feesReduce;
            } else if (nftRewardmap.rewardBoost > 0) {
                nftmap.rewardBoost = nftRewardmap.rewardBoost * (10**16);

                nftmap.typeReward = true;
            } else if (nftRewardmap.timeBoost > 0) {
                nftmap.typeReduce = true;
                nftmap.timeBoost = nftRewardmap.timeBoost;
            }

            nftmap.id.push(nftId);
        }
    }


      function removeNft(address sender,uint256 nftId, string memory nodeTypeName)
        external
        onlySentry
        nonReentrant
    {
         // require( nodeHandler._doesNodeTypeExist(nodeTypeName) == true,"NodeType not exist");
        //require(openNft, "not authorized yet");

        require(
            _attachedNft2[nodeTypeName][sender].active,
            "no nft allowed"
        );
        bool isSet;
        NftIdtoReward memory nftRewardmap = nftIdToReward[nftId];

        NftEntity storage nftmap = _attachedNft2[nodeTypeName][sender];

        for (uint256 j = 0; j < nftmap.id.length; j++) {
            if (nftmap.id[j] == nftId) {
                isSet = true;
            }
        }

        require(isSet, "nft notSet");

        bool tmp1 = nftmap.typeReward;
        bool tmp2 = nftmap.typeBoost;
        bool tmp3 = nftmap.typeReduce;

        if (nftRewardmap.typeNft == 0) {
            require(tmp1, "reward not set");
        } else if (nftRewardmap.typeNft == 1) {
            require(tmp2, "time not set");
        } else if (nftRewardmap.typeNft == 2) {
            require(tmp3, "feesR not set");
        }

        if (nftRewardmap.typeNft == 0) {
            nftmap.rewardBoost = 0;
            nftmap.typeReward = false;
        } else if (nftRewardmap.typeNft == 1) {
            nftmap.timeBoost = 0;
            nftmap.typeBoost = false;
        } else if (nftRewardmap.typeNft == 2) {
            nftmap.feesReduce = 0;
            nftmap.typeReduce = false;
        }

        uint256[] memory tab2 = new uint256[](nftmap.id.length-1);

        for (uint256 j = 0; j < nftmap.id.length; j++) {
            if (nftmap.id[j] != nftId) {
                tab2[j-1] = (nftmap.id[j]);
            }
        }

        nftmap.id = tab2;

        if (nftmap.id.length == 0) {
            nftmap.active = false;
        }
    }

    function removeNftPartener(
        address sender,
        uint256 nftId,
        uint256 partnerId,
        string memory nodeTypeName
    ) external
        onlySentry nonReentrant {
         // require( nodeHandler._doesNodeTypeExist(nodeTypeName) == true,"NodeType not exist");
        //require(openNft, "not authorized yet");

        require(
            _attachedNft2[nodeTypeName][sender].active,
            "no nft active"
        );
        bool isSet;
        NftIdtoReward memory nftRewardmap = partenerToReward[partnerId];

        NftEntity storage nftmap = _attachedNft2[nodeTypeName][sender];

        for (uint256 j = 0; j < nftmap.id.length; j++) {
            if (nftmap.id[j] == nftId) {
                isSet = true;
            }
        }

        require(isSet, "nft notSet");

        bool tmp1 = nftmap.typeReward;
        bool tmp2 = nftmap.typeBoost;
        bool tmp3 = nftmap.typeReduce;

        if (nftRewardmap.rewardBoost > 0) {
            require(tmp1, "reward already set");
        } else if (nftRewardmap.timeBoost > 0) {
            require(tmp2, "time already set");
        } else if (nftRewardmap.feesReduce > 0) {
            require(tmp3, "feesR already set");
        }

        if (nftRewardmap.feesReduce > 0) {
            nftmap.typeReduce = false;
            nftmap.feesReduce = 0;
        } else if (nftRewardmap.rewardBoost > 0) {
            nftmap.rewardBoost = 0;

            nftmap.typeReward = false;
        } else if (nftRewardmap.timeBoost > 0) {
            nftmap.typeBoost = false;
            nftmap.timeBoost = 0;
        }

        uint256[] memory tab2 = new uint256[](nftmap.id.length - 1);

        for (uint256 j = 0; j < nftmap.id.length; j++) {
            if (nftmap.id[j] != nftId) {
                tab2[j] = (nftmap.id[j]);
            }
        }

        nftmap.id = tab2;

        if (nftmap.id.length == 0) {
            nftmap.active = false;
        }
    }

    function getNFTTypeOwner(string memory nodeTypeName, address _owner)
        public
        view
        returns (NftEntity memory nodeTypeOwner)
    {
        return _attachedNft2[nodeTypeName][_owner];
    }
    
    function caluclatRewardNft(
        address user,
        string memory nodeTypeName
    ) external view returns (uint256 rewardBoost,uint256 feesReduce,uint256 timeBoost) {
        require(_attachedNft2[nodeTypeName][user].active, "no nft");

        NftEntity storage nes = _attachedNft2[nodeTypeName][user];

        address nftAddr = nes.nftAddr;
        ERC721 nftContract = ERC721(nftAddr);

        for (uint256 i = 0; i < nes.id.length; i++) {
            require(
                nftContract.ownerOf(nes.id[i]) == user,
                "One of his nft is not owned"
            );
        }

        rewardBoost += nes.rewardBoost;
        feesReduce += nes.feesReduce;
        timeBoost += nes.timeBoost;
       
    }



 function setToken(address token_) external onlySentry {
        token = token_;
    }

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
    }