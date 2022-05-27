pragma solidity ^0.8.7;
contract Test {
    function id2ids(uint id) public returns (uint256[] memory, uint256[] memory) {
        uint digits = 0;
        uint idCalLength = id;
        while (idCalLength != 0) {
            idCalLength /= 10000;
            digits++;
        }

        uint256[] memory ids = new uint[](digits);
        uint256[] memory amounts = new uint[](digits);
        for (uint256 i = 0; i < digits; i++) {
            ids[i] = id % 10000;
            amounts[i] = 1;
            id = id / 10000;
        }
    return (ids, amounts);
    }
}