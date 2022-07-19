//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockToken is ERC20, Ownable {
    using SafeMath for uint256;
    address public airdrop;
    uint256 public MAX_SUPPLY = 1000000000 ether;
    uint256 private mintedSupply;

    constructor() ERC20("Mock Token", "MOCK") {}

    // initial function
    function setAirdropAddress(address _newAirdrop) public onlyOwner {
        airdrop = _newAirdrop;
    }

    function mint(address _to, uint256 _amount) external returns (bool) {
        if (msg.sender != airdrop) {
            return false;
        }
        if (_amount == 0 || mintedSupply.add(_amount) > MAX_SUPPLY) {
            return false;
        }
        _mint(_to, _amount);
        mintedSupply = mintedSupply.add(_amount);
        return true;
    }
}
