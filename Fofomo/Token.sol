pragma solidity ^0.4.24;

contract Token {
    string public name = "FofomoToken";
    string public symbol = "FTOK"; // nickname
    uint8 public decimals = 18; // 多少次方
    uint256 public totalSupply;  // 总Token总数
    address public creator = msg.sender; // 创建者的地址

    uint256 constant internal tokenPriceInitial_ = 0.001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00001 ether;
    uint256 public tokenPriceCurrent = tokenPriceInitial_;

    struct TokenerInfo {
        uint amount; // 拥有的token数
        uint now; // 买入的时间
        uint256 unit; // 他买token时token的值
    }

    mapping(address => TokenerInfo) public Tokener; // 保存用户的token信息
    address [] private TokenerArr; // 保存所有购买token的用户地址

    //roll-in/roll-out
    event Transfer(address indexed from, string indexed behavior, uint256 amount);

    function deposit() public payable {}

    /**
    *_addr token买入
    *  买代币roll-in，amount += _value
    */
    function transferRollIn(address _addr) public payable {
        require(_addr != 0x0);
        deposit();
        // 抽取10%
        transferCoin(creator, msg.value / 10);
        uint256 amount = msg.value * 9 / 10 / tokenPriceCurrent;
        Tokener[_addr].amount += amount;
        Tokener[_addr].now = now;
        Tokener[_addr].unit = tokenPriceCurrent;
        tokenPriceCurrent += tokenPriceIncremental_;
        emit Transfer(_addr, "roll in", amount);
    }

    /**
       *_addr token转出
       *  卖代币roll-out，amount -= _value
       *_value 个数
       */
    function transferRollOut(address _addr, uint256 _value) public {
        require(_addr != 0x0);
        require(Tokener[_addr].amount >= _value);
        uint256 money = _value * tokenPriceCurrent;
        // 抽取10%
        transferCoin(creator, money / 10);
        transferCoin(_addr, money * 9 / 10);
        Tokener[_addr].amount -= _value;
        Tokener[_addr].now = now;
        Tokener[_addr].unit = tokenPriceCurrent;
        tokenPriceCurrent -= tokenPriceIncremental_;
        TokenerArr.push(_addr);
        emit Transfer(_addr, "roll out", _value);
    }

    function transferCoin(address _to, uint _coins) private {
        _to.transfer(_coins);
    }

    // 返回token奖池余额
    function getCurrentBalance() public constant returns (uint256) {
        return address(this).balance;
    }

    // 返回token玩家地址
    function getTokenAddress() public constant returns (address[]) {
        return TokenerArr;
    }

    // 返回每个token玩家的token数
    function getTokenPer(address _addr) public constant returns (uint256) {
        return Tokener[_addr].amount;
    }
}