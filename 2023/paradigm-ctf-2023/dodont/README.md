# Solve Method
The target address mentioned in the problem, '0x2BBD66fC4898242BDBD2583BBe1d76E8b8f71445,' is a contract deployed by Dododex, and it's been almost two years since it was deployed.

Our approach to this was to first check if there were any vulnerabilities discovered in this contract in the past.

As a result, we found the following links:

https://www.halborn.com/blog/post/explained-the-dodo-dex-hack-march-2021

https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/dodo_flashloan_exp.sol

We ran the publicly available proof of concept (POC) with minimal modifications and successfully resolved the issue. 😅