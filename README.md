### Features
- ERC-20 token compatibility
- Customizable vesting schedules with cliff periods and release intervals
- Beneficiaries can claim vested tokens
- Owner can withdraw unallocated tokens

### How to Use
1. Deploy the contract with the ERC-20 token address.
2. Create vesting schedules for beneficiaries.
3. Beneficiaries can call the `releaseTokens` function to claim their tokens after the cliff period.
