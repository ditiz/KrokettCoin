// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract KrowketteCoin {
    mapping(address => uint256) public balanceOf;

    string public name = "KrowketteCoin";
    string public symbol = "KRO";
    uint256 public max_supply = 42000000000000;
    uint256 public unspent_supply = 0;
    uint256 public spendable_supply = 0;
    uint256 public circulating_supply = 0;
    uint256 public reward = 50000000;
    uint256 public timeOfLastHalving = block.timestamp;
    uint256 public timeOfLastIncrease = block.timestamp;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, uint256 value);

    constructor() {
        timeOfLastHalving = block.timestamp;
    }

    function updateSupply() internal returns (uint256) {
        if (block.timestamp - timeOfLastHalving >= 2100000 minutes) {
            reward /= 2;
            timeOfLastHalving = block.timestamp;
        }

        if (block.timestamp - timeOfLastIncrease >= 150 minutes) {
            uint256 increaseAmount = ((block.timestamp - timeOfLastIncrease) /
                150 seconds) * reward;
            spendable_supply += increaseAmount;
            unspent_supply += increaseAmount;
            timeOfLastIncrease = block.timestamp;
        }

        circulating_supply = spendable_supply - unspent_supply;

        return circulating_supply;
    }

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Ad the same to the recipient

        updateSupply();

        /* Notify anyone listening that the transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }

    function mint() public payable {
        require(balanceOf[msg.sender] + msg.value >= balanceOf[msg.sender]); // Check for overflows
        uint256 _value = msg.value / 100000000;

        updateSupply();

        require(unspent_supply - _value <= unspent_supply);
        unspent_supply -= _value; // Remove from unspent supply
        balanceOf[msg.sender] += _value; // Add the same to hte recipient

        updateSupply();

        emit Mint(msg.sender, _value);
    }

    function withdraw(uint256 amountToWithdraw) public returns (bool) {
        require(balanceOf[msg.sender] >= amountToWithdraw);
        require(
            balanceOf[msg.sender] - amountToWithdraw <= balanceOf[msg.sender]
        );

        // Balance check in KRO, then converted into Wei
        balanceOf[msg.sender] -= amountToWithdraw;

        // Added back to supply in KRO
        unspent_supply += amountToWithdraw;

        //Convert into Wei
        amountToWithdraw *= 100000000;

        payable(msg.sender).transfer(amountToWithdraw);

        updateSupply();

        return true;
    }
}
