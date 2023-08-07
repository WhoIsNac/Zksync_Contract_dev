// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library IterableNodeTypeMapping {
    struct NodeType {
        string nodeTypeName;
        uint256 nodePrice;
        uint256 claimTime;
        uint256 rewardAmount;
        uint256 claimTaxBeforeTime;
        uint256 cashoutFee;
        uint256 creationDate;
		uint256 count;
		uint256 max;
		uint256 maxLevelUpGlobal;
		uint256 maxLevelUpUser;
        uint256 burnDate;
        uint256 nodePricePartener;
    }
    struct Map {
        string[] keys;
        mapping(string => NodeType) values;
        mapping(string => uint256) indexOf;
        mapping(string => bool) inserted;
    }
    function get(Map storage map, string memory key) public view returns (NodeType storage) {
        return map.values[key];
    }
    function getIndexOfKey(Map storage map, string memory key)
    public
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }
    function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (string memory)
    {
        return map.keys[index];
    }
    function getValueAtIndex(Map storage map, uint256 index)
    public
    view
    returns (NodeType memory)
    {
        return map.values[map.keys[index]];
    }
    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }
    function set(
        Map storage map,
        string memory key,
        NodeType memory value
    ) public {
        if (map.inserted[key]) {
            map.values[key] = value;
        } else {
            map.inserted[key] = true;
            map.values[key] = value;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
    function remove(Map storage map, string memory key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        delete map.values[key];
        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        string memory lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
