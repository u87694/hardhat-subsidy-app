// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error GasStation__NotProvider();
error GasStation__RequestAlreadySubmitted();
error GasStation__CardAlreadyIssued();
error GasStation__CardNotIssuedToAddress();
error GasStation__NotValidCard();
error GasStation__InsufficientAmount();
error GasStation__CurrentCardNumberSetTo0();

contract GasAgency is VRFConsumerBaseV2 {

    // VRFCoordinatorV2Interface
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 public requestId;    

    // GasStation
    address payable private immutable i_gasStation;
    uint256 public constant DISCOUNT_PERCENTAGE = 20;

    // Cards
    uint256 public currentCardNumber;
    struct Card {
        uint256 cardNumber;
        address payable user;
        string name;
        bool isValid;
    }
    mapping (uint256 => Card) private cards;
    mapping (address => bool) private issuedCardsOnAddresses;
    mapping (address => uint256) public addressToCardnumber;

    // Requests
    struct Request {
        address payable user;
        string name;
    }
    uint256 private requestCounter;
    mapping (uint256 => Request) private idToRequests;
    mapping (address => bool) private submittedRequests;

    // Events
    event NewCardCreated (
        uint256 indexed cardNumber,
        address payable indexed user,
        string name,
        bool isActive
    );

    // Modifier
    modifier onlyAgency () {
        if (msg.sender != i_gasStation) revert GasStation__NotProvider();
        _;
    }

   modifier onlyValidCardOwners (uint256 _cardNumber) {
        if (!issuedCardsOnAddresses[msg.sender]) {
            revert GasStation__CardNotIssuedToAddress();
        }
        Card memory _card = cards[_cardNumber];
        bool validity = _card.isValid;
        if (!validity) {
            revert GasStation__NotValidCard();
        }
        _;
    }

    constructor (
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address payable gasStation
    ) VRFConsumerBaseV2 (vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_gasStation = gasStation;
        requestCounter = 0;
    }

    function approveCards (uint256 _requestId) onlyAgency () public returns (uint256) {
        Request memory request = idToRequests[_requestId];
        if (_checkCardIssued(request.user)) {
            revert GasStation__CardAlreadyIssued();
        }
        if (currentCardNumber == 0) {
            revert GasStation__CurrentCardNumberSetTo0();
        }
        Card memory card = Card(currentCardNumber, request.user, request.name, true);
        cards[card.cardNumber] = card;
        issuedCardsOnAddresses[card.user] = true;
        addressToCardnumber[card.user] = card.cardNumber;
        emit NewCardCreated (card.cardNumber, card.user, card.name, card.isValid);
        currentCardNumber = 0;
        return addressToCardnumber[card.user];
    }

    function revokeCardValidity (uint256 _cardNumber) onlyAgency () public {
        Card memory card = cards[_cardNumber];
        address _user = card.user;
        string memory _name = card.name;
        delete cards[_cardNumber];
        Card memory changedCard = Card(_cardNumber, payable(_user), _name, false);
        cards[_cardNumber] = changedCard;
    }

    function invokeCardValidity (uint256 _cardNumber) onlyAgency () public  {
        Card memory card = cards[_cardNumber];
        address _user = card.user;
        string memory _name = card.name;
        delete cards[_cardNumber];
        Card memory changedCard = Card(_cardNumber, payable(_user), _name, true);
        cards[_cardNumber] = changedCard;      
    }

    function requestForCard (string memory _name, address _user) public {
        if (_checkForNewRequests(_user)) {
            revert GasStation__RequestAlreadySubmitted();
        }
        requestCounter = requestCounter + 1;
        submittedRequests[_user] = true;
        Request memory request = Request(payable(_user), _name);
        idToRequests[requestCounter] = request;
    }

    function requestNewUniqueCardNumber () onlyAgency () public {
        // send request for random card number which will be used later during approval
        uint256 _requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
        requestId = _requestId;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        currentCardNumber = randomWords[0];
        currentCardNumber = currentCardNumber / 10**65;
    }

    function payForGas () public payable {
        uint256 amount = msg.value;
        uint256 userBalance = address(msg.sender).balance;
        if (userBalance < amount) {
            revert GasStation__InsufficientAmount();
        }
        (bool sent, ) = i_gasStation.call{ value: msg.value }("");
        require(sent, "Payment failed try again!");
    }

    function payForGasWithCard (uint256 cardNumber) public payable onlyValidCardOwners (cardNumber) {
        uint256 amount = msg.value;
        uint256 userBalance = address(msg.sender).balance;
        uint256 discountedAmount = amount - (amount/100 * DISCOUNT_PERCENTAGE);
        if (userBalance < discountedAmount) {
            revert GasStation__InsufficientAmount();
        }
        (bool sent, ) = i_gasStation.call{ value: discountedAmount}("");
        require(sent, "Payment failed try again!");
    }

    function _checkForNewRequests (address _user) private view returns (bool) {
        bool _check = submittedRequests[_user];
        return _check;
    }

    function _checkCardValidity (uint256 _cardNumber) public view returns (bool) {
        Card memory card = cards[_cardNumber];
        bool _check = card.isValid;
        return _check;
    }

    function _checkCardIssued (address _user) private view returns (bool) {
        bool _check = issuedCardsOnAddresses[_user];
        return _check;
    }

    function gasStationBalance () public view onlyAgency returns (uint256) {
        return address(i_gasStation).balance;
    }

    function getMyCardNumber () public view returns (uint256) {
        return addressToCardnumber[msg.sender];
    }

    function getUserFromRequestId (uint256 _requestId) public view returns (string memory, address) {
        Request memory requestObj = idToRequests[_requestId];
        return (requestObj.name, payable(requestObj.user));
    }
}