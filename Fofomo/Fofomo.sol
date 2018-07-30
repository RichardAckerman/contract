pragma solidity ^0.4.24;

library FofDataSets {
    // team
    // 0 = 鲸whales
    // 1 = 熊bears
    // 2 = 蛇sneks
    // 3 = 牛bulls
    struct PlayerInfo {
        address addr;   // player address
        bytes32 name;   // player name
        uint keyNum;    // 拥有key的数量
        uint bonus;     // key分红
        address referees; // 推荐人地址
    }

    struct TeamBalance {
        uint256 total;      // 买入总额
        uint256 potCoin;    // 总额按百分比进入奖池的额度
    }
}

library NameFilter {
    /**
     * @dev filters name strings
     * -将大写改为小写。
     * -确保它不会以空格开始/结束
     * -确保它不包含一行中的多个空格
     * -不能仅仅是数字。
     * -不能从0x开始
     * -限制字符为A-Z、A-Z、0-9。
     * @return 以bytes32格式重新处理的字符串
     */
    function nameFilter(string _input)
    internal
    pure
    returns (bytes32){
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require(_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length - 1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                // require character is a space
                    _temp[i] == 0x20 ||
                // OR lowercase a-z
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                // or 0-9
                (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require(_temp[i + 1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}
/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    *  todo 乘法
    */
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c){
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    *  todo 减法
    */
    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256){
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    *  todo 加法
    */
    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c){
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     todo 平方根
     */
    function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y){
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
      todo 平方
     */
    function sq(uint256 x)
    internal
    pure
    returns (uint256){
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
      todo y次方
     */
    function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256){
        if (x == 0)
            return (0);
        else if (y == 0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++)
                z = mul(z, x);
            return (z);
        }
    }
}

contract Fofevents {

}

contract Fofomo {
    using NameFilter for string;
    using SafeMath for *;
    linkTokenInterface constant private tokenContract = linkTokenInterface(0x05270317611398E3897D8493b68BC597BB88BbcB);
    string public name = "Fofomo";
    string public symbol = "FOFM"; // nickname
    uint public totalKey;  // Key总数
    address public creator = msg.sender; // 创建者的地址
    uint256 constant private rndInit_ = 1 hours;                // 一个小时后开启游戏
    uint256 constant private rndInc_ = 30 seconds;              // 每次买key增加30s
    uint256 constant private rndMax_ = 6 hours;                 // 最长6h

    uint256 constant internal keyPriceInitial_ = 0.001 ether;
    uint256 constant internal keyPriceIncremental_ = 0.00001 ether;
    uint256 public registrationFee_ = 10 finney;            // price to register a name
    uint256 public keyPriceCurrent = keyPriceInitial_;

    uint256 public overMoment = now + rndMax_; // 本轮游戏的结束时刻

    address [] Luckyer; // 保存最后三名幸运儿的地址

    /**
     * 玩家购买key，传入地址addr，先判断pIDxAddr_[addr] 值是否为0，为0则是第一次购买，不为0为第二次
     * 第1次购买：获取playerArr的长度，+1为他的pid，存入pIDxAddr_，通过pid存入玩家信息到playerxID_
     *           当注册name的时候，先判断pIDxName_的值是否为0，为0则是该名字第一次注册，否则请更换名称
     * 第2+次购买：通过pid得到玩家信息，再更改玩家信息
     */
    mapping(address => uint256) public pIDxAddr_;      // (addr => pID) returns player id by address
    mapping(bytes32 => uint256) public pIDxName_;      // (name => pID) returns player id by name
    mapping(uint256 => FofDataSets.PlayerInfo) public playerxID_; // (pId => data) returns player data by id
    address [] public playerArr; // 玩家地址数组，下标+1就是pid

    // 0 = 鲸whales
    // 1 = 熊bears
    // 2 = 蛇sneks
    // 3 = 牛bulls
    // 买入key时
    //50% to 奖金池, 10% to 推荐人, 3% to 创建者, 1% to 空投,todo 30% to key池, 6% to token池
    //43% to 奖金池, 10% to 推荐人, 3% to 创建者, 1% to 空投,todo 43% to key池, 0% to token池
    //20% to 奖金池, 10% to 推荐人, 3% to 创建者, 1% to 空投,todo 56% to key池, 10% to token池
    //35% to 奖金池, 10% to 推荐人, 3% to 创建者, 1% to 空投,todo 43% to key池, 8% to token池

    // 一轮游戏结束时
    //48% to winner, 3% to key中随机选10个人，按key分配, 2% to 创建者, 24% to 下一轮,todo 14% to key池, 9% to token池
    //48% to winner, 3% to key中随机选10个人，按key分配, 2% to 创建者, 24% to 下一轮,todo 23% to key池, 0% to token池
    //48% to winner, 3% to key中随机选10个人，按key分配, 2% to 创建者, 9% to 下一轮,todo 19% to key池, 19% to token池
    //48% to winner, 3% to key中随机选10个人，按key分配, 2% to 创建者, 9% to 下一轮,todo 29% to key池, 9% to token池

    mapping(uint256 => FofDataSets.TeamBalance) public teamPot; // 存储4个队的奖池余额

    function deposit() public payable {}

    //开局每个地址只有1ETH的最大购买额度，当智能合约内的ETH达到100个时，不再限制
    modifier isWithinLimits(uint256 _eth) {// todo 这个require不通过
        require(getCurrentBalance() > 100 ether || _eth < 1 ether);
        _;
    }

    //    constructor() payable{}
    /**
    * 买入key
    * 买入者地址 _addr
    * 加入队伍 _team
    * 推荐人地址 _referrer(没有推荐人传入0x0)
    * 每次买之前 需到合约中查出他的推荐人
    */
    function keyRollIn(address _addr, uint _team, address _referrer) isWithinLimits(msg.value) public payable {
        require(_addr != 0x0);
        deposit();
        uint allCoin = msg.value;
        uint keyNum = allCoin / keyPriceCurrent;
        totalKey += keyNum;
        keyPriceCurrent += keyPriceIncremental_;
        // 保存最后3个买key人的地址
        if (Luckyer.length <= 3) {
            Luckyer.push(_addr);
        } else {
            Luckyer[0] = Luckyer[1];
            Luckyer[1] = Luckyer[2];
            Luckyer[2] = _addr;
        }
        // 第一次买
        if (pIDxAddr_[_addr] == 0) {
            pIDxAddr_[_addr] = playerArr.length + 1;
            playerArr.push(_addr);
            playerxID_[pIDxAddr_[_addr]] = FofDataSets.PlayerInfo(_addr, "", keyNum, 0, _referrer);
        } else {// 第二次买
            playerxID_[pIDxAddr_[_addr]].keyNum += keyNum;
        }
        // 0 = 鲸whales
        // 1 = 熊bears
        // 2 = 蛇sneks
        // 3 = 牛bulls
        // 4 = 空投奖池
        if (_team == 0) {
            teamPot[0].total += allCoin;
            teamPot[0].potCoin += allCoin.mul(50) / 100;
            // 给key池30%
            bonusToKeyPot(allCoin.mul(30) / 100);
            // 给token池6%
            bonusToTokenPot(allCoin.mul(6) / 100);
        } else if (_team == 1) {
            teamPot[1].total += allCoin;
            teamPot[1].potCoin += allCoin.mul(43) / 100;
            // 给key池43%
            bonusToKeyPot(allCoin.mul(43) / 100);
            // 给token池0%
        } else if (_team == 2) {
            teamPot[2].total += allCoin;
            teamPot[2].potCoin += allCoin.mul(20) / 100;
            // 给key池56%
            bonusToKeyPot(allCoin.mul(56) / 100);
            // 给token池10%
            bonusToTokenPot(allCoin.mul(10) / 100);
        } else if (_team == 3) {
            teamPot[3].total += allCoin;
            teamPot[3].potCoin += allCoin.mul(35) / 100;
            // 给key池43%
            bonusToKeyPot(allCoin.mul(43) / 100);
            // 给token池8%
            bonusToTokenPot(allCoin.mul(8) / 100);
        }
        // 给推荐人10%
        if (playerxID_[pIDxAddr_[_addr]].referees != 0x0) {
            transferCoin(playerxID_[pIDxAddr_[_addr]].referees, allCoin.mul(10) / 100);
        }
        // 给创建者3%
        transferCoin(creator, allCoin.mul(3) / 100);
        // 给空投1%
        teamPot[4].total += allCoin;
        teamPot[4].potCoin += allCoin.mul(1) / 100;
        // 根据allCoin判断 5% 几率中，返还空投奖励的奖池占比
        if (airdropSign(100) < 5) {
            if (allCoin >= 0.1 ether && allCoin < 1 ether) {
                transferCoin(_addr, teamPot[4].potCoin.mul(25) / 100);
            } else if (allCoin >= 1 ether && allCoin < 10 ether) {
                transferCoin(_addr, teamPot[4].potCoin.mul(50) / 100);
            } else if (allCoin >= 10 ether) {
                transferCoin(_addr, teamPot[4].potCoin.mul(75) / 100);
            }
        }
        // 剩余时间加30s
        overMoment += rndInc_ * keyNum;
        overMoment = overMoment > 6 hours ? 6 hours : overMoment;
    }

    /**
    * 一轮游戏结束了，开始分钱
    * ①总奖池48%分给最后三个买key的人,倒数第一:倒数第二:倒数第三 = 3:2:1
    * ②总奖池3%为幸运奖池,随机10个人,按key分配
    * ③key奖池得一部分
    * ④token奖池得一部分
    * ⑤2%给创建者
    * ⑥一部分给下一轮
    */
    function gameOver() public {
        uint _now = now;
        require(_now >= overMoment);
        uint totalPot = getTotalPot();
        // 分48%
        transferCoin(Luckyer[0], totalPot.mul(8) / 100);
        transferCoin(Luckyer[1], totalPot.mul(16) / 100);
        transferCoin(Luckyer[2], totalPot.mul(24) / 100);
        // 分3% 幸运奖池
        splitLuckyPot();

        //2%给创建者
        transferCoin(creator, totalPot.mul(2) / 100);

        //key奖池分红  &&  token奖池分红   &&  一部分给下一轮
        // 0 = 鲸whales 14%  9%  24%
        // 1 = 熊bears  23%  0%  24%
        // 2 = 蛇sneks  19%  19% 9%
        // 3 = 牛bulls  29%  9%  9%
        bonusToKeyPot(teamPot[0].potCoin.mul(14) / 100);
        bonusToKeyPot(teamPot[1].potCoin.mul(23) / 100);
        bonusToKeyPot(teamPot[2].potCoin.mul(19) / 100);
        bonusToKeyPot(teamPot[3].potCoin.mul(29) / 100);

        bonusToTokenPot(teamPot[0].potCoin.mul(9) / 100);
        bonusToTokenPot(teamPot[2].potCoin.mul(19) / 100);
        bonusToTokenPot(teamPot[3].potCoin.mul(9) / 100);

        teamPot[0].potCoin = teamPot[0].potCoin.mul(24) / 100;
        teamPot[1].potCoin = teamPot[1].potCoin.mul(24) / 100;
        teamPot[2].potCoin = teamPot[2].potCoin.mul(9) / 100;
        teamPot[3].potCoin = teamPot[3].potCoin.mul(9) / 100;
        reset();
    }

    // 注册nickname
    function registerName(string _nameString) public payable {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        require(_paid >= registrationFee_, "umm.....  you have to pay the name fee");
        require(pIDxName_[_name] == 0, "sorry that names already taken");
        playerxID_[pIDxAddr_[_addr]].name = _name;
        pIDxName_[_name] = pIDxAddr_[_addr];
    }

    // 分幸运奖池
    function splitLuckyPot() private {
        uint coin = getTotalPot().mul(3) / 100;
        uint subInit = airdropSign(100000000) % playerArr.length;
        for (uint i = 0; i < 10; i++) {
            uint sub = subInit + i;
            if (sub >= playerArr.length) {
                sub = sub % playerArr.length;
            }
            transferCoin(playerArr[sub], playerxID_[pIDxAddr_[playerArr[sub]]].keyNum / totalKey * coin);
        }
    }

    // 获取总的奖池余额
    function getTotalPot() constant public returns (uint){
        uint totalPot = 0;
        for (uint i = 0; i < 4; i++) {
            totalPot += teamPot[i].potCoin;
        }
        return totalPot;
    }

    // key池分红
    function bonusToKeyPot(uint coin) private {
        for (uint i = 0; i < playerArr.length; i++) {
            playerxID_[pIDxAddr_[playerArr[i]]].bonus += playerxID_[pIDxAddr_[playerArr[i]]].keyNum / totalKey * coin;
            transferCoin(playerArr[i], playerxID_[pIDxAddr_[playerArr[i]]].keyNum / totalKey * coin);
        }
    }

    // token池分红
    function bonusToTokenPot(uint coin) private {
        for (uint i = 0; i < tokenContract.getTokenAddress().length; i++) {
            transferCoin(tokenContract.getTokenAddress()[i], tokenContract.getTokenPer(tokenContract.getTokenAddress()[i]) / tokenContract.totalSupply() * coin);
        }
    }

    function transferCoin(address _to, uint _coins) private {
        _to.transfer(_coins);
    }

    // 返回奖池余额
    function getCurrentBalance() public constant returns (uint256) {
        return address(this).balance;
    }

    // 提现
    function withdraw(address _addr) public {
        if (_addr == msg.sender) {
            transferCoin(_addr, playerxID_[pIDxAddr_[_addr]].bonus);
        }
    }

    // 每一轮结束了重置函数
    function reset() private {
        // todo
    }

    // 返回空投sign值
    // 该值小于5的概率为5%
    function airdropSign(uint _per)
    private
    view
    returns (uint256){
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)
            )));
        return ((seed - ((seed / _per) * _per)));
    }
}

interface linkTokenInterface {
    function getTokenAddress() external returns (address[]);

    function getTokenPer(address _addr) external returns (uint256);

    function totalSupply() external returns (uint256);
}