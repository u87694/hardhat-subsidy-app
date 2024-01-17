const { network, ethers } = require("hardhat")
const { networkConfig, gasStation } = require("../helper.hardhat.config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    const args = [
        networkConfig[chainId]["vrfCoordinatorV2"],
        networkConfig[chainId]["gasLane"],
        networkConfig[chainId]["subscriptionId"],
        networkConfig[chainId]["callbackGasLimit"],
        gasStation,
    ]

    const gasAgency = await deploy ("GasAgency", {
        from: deployer,
        args: args,
        log: true,
        blockConfirmations: network.config.blockConfirmations || 1,
    })

}
