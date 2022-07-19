// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IToken.sol";

contract Airdrop is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    address public signer;
    address public token;
    uint256 public price;
    EnumerableSet.AddressSet private whitelist;
    mapping(address => uint256[]) public locksForUsers;

    struct TokenLock {
        uint256 lockDate;
        uint256 amount;
        uint256 intialAmount;
        uint256 unlockDate;
        uint256 lockID;
        address owner;
    }

    TokenLock[] public tokenLocks;

    // This is a packed array of booleans.
    mapping(address => bool) private claimed;

    constructor(address _token) {
        token = _token;
    }

    // admin function
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // function addWhitelist(address _account) public onlyOwner {
    //     whitelist.add(_account);
    // }

    // function removeWhitelist(address _account) public onlyOwner {
    //     whitelist.remove(_account);
    // }

    function dropTokens(address _signer, uint256 _nonce, uint256 _amount, bytes memory signature) public returns (bool) {
        bytes32 messageHash = getMessageHash(_signer, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(
            recoverSigner(ethSignedMessageHash, signature) == msg.sender,
            "You didn't sign."
        );
        require(
            IToken(token).mint(address(this), _amount),
            "mint fail"
        );
        return true;
    }

    function lockToken(
        uint256 _amount,
        address _withdrawer,
        uint256 _no_of_vesting
    ) internal {
        require(_no_of_vesting <= 12, "Max number of vesting is 12");
        uint256 amountLocked = _amount;
        uint256 amountPerVesting = amountLocked.div(_no_of_vesting);
        uint256 lockDate = block.timestamp;
        uint256 unlockPeriodPerVesting = 30 days;
        for (uint256 i = 0; i < _no_of_vesting; i++) {
            TokenLock memory token_lock;
            token_lock.lockDate = lockDate;
            token_lock.amount = amountPerVesting;
            token_lock.unlockDate = lockDate.add(i.mul(unlockPeriodPerVesting));
            token_lock.owner = _withdrawer;
            token_lock.lockID = tokenLocks.length;
            tokenLocks.push(token_lock);
            locksForUsers[_withdrawer].push(token_lock.lockID);
        }
    }

    function unlockToken(
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    ) external nonReentrant {
        TokenLock storage userLock = tokenLocks[_lockID];
        require(userLock.owner == msg.sender, "Lock Mismatch!");
        require(userLock.unlockDate < block.timestamp, "Cannnot withdraw yet!");
        userLock.amount = userLock.amount.sub(_amount);
        if (userLock.amount == 0) {
            uint256[] storage userLocks = locksForUsers[msg.sender];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
        }
        uint256 vaultBalance = IERC20(token).balanceOf(address(this));
        if (vaultBalance < _amount) {
            require(
                IToken(token).mint(address(this), _amount.sub(vaultBalance)),
                "mint fail"
            );
        }
        IERC20(token).transfer(msg.sender, _amount);
    }

    function getUserLocks(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return locksForUsers[_account];
    }

    function getLock(uint256 _index) public view returns (TokenLock memory) {
        return tokenLocks[_index];
    }

    function purchaseTokens(uint256 _amount) external payable {
        require(
            msg.value == price.mul(_amount).div(10**18),
            "Not enough value"
        );
        uint256 vaultBalance = IERC20(token).balanceOf(address(this));
        if (vaultBalance < _amount) {
            IToken(token).mint(address(this), _amount.sub(vaultBalance));
        }
        IERC20(token).transfer(msg.sender, _amount);
    }

    function getMessageHash(address _signer, uint256 _nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_signer, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
