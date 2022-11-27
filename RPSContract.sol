// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title RPSContract
 * @dev Contract that implements rock paper scissors game
 */
contract RPSContract {

    enum Choice {
        None,
        Rock,
        Paper,
        Scissors
    }

    enum Status {
        Unregistered,
        Commit,
        Reveal,
        Finish
    }

    struct Player {
        address payable id;
        Choice choice;
        Status status;
        bytes32 move;
    }

    uint public bet = 0;
    Player player1 = Player(payable(address(0x0)), Choice.None, Status.Unregistered, 0x0);
    Player player2 = Player(payable(address(0x0)), Choice.None, Status.Unregistered, 0x0);

    event Registered(address player);
    event Committed(address player);
    event Revealed(address player, Choice choice);
    event Payed(address player, uint amount);

    modifier vacantPlace() {
        require((player1.id == payable(address(0x0)) || player2.id == payable(address(0x0))) &&
                (player1.choice == Choice.None || player2.choice == Choice.None) &&
                (player1.move == 0x0 || player2.move == 0x0) && 
                (player1.status == Status.Unregistered || player2.status == Status.Unregistered));
        _;
    }

     modifier validBet() {
        require(msg.value > 0);
        _;
    }

    function register() public payable vacantPlace validBet returns (uint) {
        if (player1.status == Status.Unregistered) {
            if (player2.status == Status.Unregistered){
                bet = msg.value;
            } else {
                require(bet == msg.value, "Invalid bet");
            }
            player1.id = payable(msg.sender);
            player1.status = Status.Commit;
            emit Registered(msg.sender);
            return 1;
        } else if (player2.status == Status.Unregistered) {
            if (player1.status == Status.Unregistered){
                bet = msg.value;
            } else {
                require(bet == msg.value, "Invalid bet");
            }
            player2.id = payable(msg.sender);
            player2.status = Status.Commit;
            emit Registered(msg.sender);
            return 2;
        }
        return 0;
    }

    modifier timeToCommit() {
        require((player1.id != payable(address(0x0)) && player2.id != payable(address(0x0))) &&
                (player1.choice == Choice.None && player2.choice == Choice.None) &&
                (player1.move == 0x0 || player2.move == 0x0) && 
                (player1.status == Status.Commit || player2.status == Status.Commit));
        _;
    }

    modifier isRegistered() {
        require (msg.sender == player1.id || msg.sender == player2.id);
        _;
    }

    function commit(bytes32 move) public timeToCommit isRegistered returns (bool) {
        if (msg.sender == player1.id && player1.move == 0x0) {
            player1.move = move;
            player1.status = Status.Reveal;
        } else if (msg.sender == player2.id && player2.move == 0x0) {
            player2.move = move;
            player2.status = Status.Reveal;
        } else {
            return false;
        }
        emit Committed(msg.sender);
        return true;
    }

    modifier timeToReveal() {
        require((player1.choice == Choice.None || player2.choice == Choice.None) &&
                (player1.move != 0x0 && player2.move != 0x0) && 
                (player1.status == Status.Reveal || player2.status == Status.Reveal));
        _;
    }

    function reveal(Choice choice, string calldata pad) public timeToReveal isRegistered returns (bool) {
        if (msg.sender == player1.id){
            require(sha256(abi.encodePacked(msg.sender, choice, pad)) == player1.move, "reveal validation failed");
            player1.choice = choice;
            player1.status = Status.Finish;
            emit Revealed(msg.sender, choice);
            return true;
        } else if (msg.sender == player2.id){
            require(sha256(abi.encodePacked(msg.sender, choice, pad)) == player2.move, "reveal validation failed");
            player2.choice = choice;
            player2.status = Status.Finish;
            emit Revealed(msg.sender, choice);
            return true;
        }
        return false;
    }


    modifier timeToPay() {
        require((player1.choice != Choice.None && player2.choice != Choice.None) &&
                (player1.move != 0x0 && player2.move != 0x0) &&
                (player1.status == Status.Finish && player2.status == Status.Finish));
        _;
    }


     function makeResult() public timeToPay isRegistered returns (uint) {
        if (player1.choice == player2.choice) {
            address payable addrTo1 = player1.id;
            address payable addrTo2 = player1.id;
            uint amount = bet;
            reset();
            addrTo1.transfer(amount);
            addrTo2.transfer(amount);
            emit Payed(addrTo1, amount);
            emit Payed(addrTo2, amount);
            return 0;
        } else if ((player1.choice == Choice.Rock     && player2.choice == Choice.Scissors) ||
                   (player1.choice == Choice.Paper    && player2.choice == Choice.Rock)     ||
                   (player1.choice == Choice.Scissors && player2.choice == Choice.Paper)) {
            address payable addrTo = player1.id;
            uint amount = 2 * bet;
            reset();
            addrTo.transfer(amount);
            emit Payed(addrTo, amount);
            return 1;
        } else {
            address payable addrTo = player2.id;
            uint amount = 2 * bet;
            reset();
            addrTo.transfer(amount);
            emit Payed(addrTo, amount);
            return 2;
        }
    }

    function reset() private {
        player1 = Player(payable(address(0x0)), Choice.None, Status.Unregistered, 0x0);
        player2 = Player(payable(address(0x0)), Choice.None, Status.Unregistered, 0x0);
        bet = 0;
    }

    function getMove(Choice choice, string calldata pad) public returns (bytes32) {
        // For debug purposes only!!!
        return sha256(abi.encodePacked(msg.sender, choice, pad));
    }
}
