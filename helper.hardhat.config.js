const networkConfig = {
    80001: {
        name: "mumbai",
        subscriptionId: 1532,
        gasLane: "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
        callbackGasLimit: "500000", // 500,000 gas
        vrfCoordinatorV2: "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed",
    }
}

const gasStation = "0x4093a6dfc8DA488950cF12272c954EA708C432A2"

module.exports = {
    networkConfig,
    gasStation
}