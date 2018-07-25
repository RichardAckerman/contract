pragma solidity ^0.4.0;

contract P11C5 {
    string public contractName;
    uint public gameType = 4;// 类型：应该为3 (龙虎斗1，竞猜2，百家乐3，11选五4)
    address public creator = msg.sender; // 创建者的地址
    uint public creationTime;
    uint public historyTotalCoins = 0; // 历史下注总额

    uint public limit;//下注额度
    uint public totalCoins = 0; // 当前一局下注总额
    uint [] randomNum; // 保存传入的随机数
    uint [5] fiveNum; // 最后结果5个数
    address [] player; // 下注者地址数组

    struct BetChoose {
        uint[] betArr; // 每一次下注的结构体
    }

    mapping(address => BetChoose []) R1Choose;
    mapping(address => BetChoose []) R2Choose;
    mapping(address => BetChoose []) R3Choose;
    mapping(address => BetChoose []) R4Choose;
    mapping(address => BetChoose []) R5Choose;
    mapping(address => BetChoose []) R6Choose;
    mapping(address => BetChoose []) R7Choose;
    mapping(address => BetChoose []) R8Choose;//任选r1-r8
    mapping(address => BetChoose []) Z2Choose;
    mapping(address => BetChoose []) Z3Choose;//直选z2-z3
    mapping(address => BetChoose []) G2Choose;
    mapping(address => BetChoose []) G3Choose;//组选g2-g3

    event returnBetResult(bool _bool, address _addr, string _msg); // 返回是否下注成功
    event returnSettleRes(uint[5]); // 返回最后的出牌结果

    function deposit() public payable {}


    //    uint[] testArr1;
    //    uint[] testArr2;
    //    uint testNum1;
    //    uint testNum2;
    //    uint testNum3;
    //
    //    function aaaaaa() public constant returns (address[], uint[], uint[], uint, uint, uint) {
    //        return (player, testArr1, testArr2, testNum1, testNum2, testNum3);
    //    }
    //
    //    function setTestResult(uint[5] _betArr) public payable {
    //        fiveNum = _betArr;
    //    }


    // 获取公共数据
    function getPublicData() public constant returns (string, uint, address, uint, uint){
        return (contractName, gameType, creator, creationTime, historyTotalCoins);
    }

    // 返回当前合约账户的余额
    function getCurrentBalance() public constant returns (uint256) {
        return address(this).balance;
    }
    /*
     * 转账函数
     * @_to 目标地址
     * @_coins 金额
     */
    function transferCoin(address _to, uint _coins) private {
        _to.transfer(_coins);
    }

    /*
    * 构造函数
    * @_limit 下注额度
    * @_name 合约名称
    */
    constructor(uint _limit, string _name) public{
        creationTime = block.timestamp;
        limit = _limit;
        contractName = _name;
    }

    /*
    * 下注函数
    * @_addr 下注账户地址
    * @_playClass 玩法        任选: r1-r8  直选: z2-z3  组选: g2-g3
    * @_betArr 下注数组对象
    * @_ran 随机数
    * @_coin 下注金额
    */
    function sendBetInfo(address _addr, string _playClass, uint[] _betArr, uint _ran, uint _coin) public payable {
        totalCoins += _coin;
        deposit();
        if (getCurrentBalance() / 32 < totalCoins) {// todo 下注失败
            totalCoins -= _coin;
            transferCoin(_addr, _coin);
            emit returnBetResult(false, _addr, "下注失败");
        } else {
            historyTotalCoins += _coin;
            randomNum.push(_ran);
            player.push(_addr);
            BetChoose memory c;
            c.betArr = _betArr;
            if (stringsEqual(_playClass, "r1")) {
                R1Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r2")) {
                R2Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r3")) {
                R3Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r4")) {
                R4Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r5")) {
                R5Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r6")) {
                R6Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r7")) {
                R7Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "r8")) {
                R8Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "z2")) {
                Z2Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "z3")) {
                Z3Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "g2")) {
                G2Choose[_addr].push(c);
            }
            if (stringsEqual(_playClass, "g3")) {
                G3Choose[_addr].push(c);
            }
            emit returnBetResult(true, _addr, "下注成功");
        }
    }

    /*
    * 结算函数
    */
    function settleFunc() public {
        getResultFive(); //todo
        settleBegin();
        //        settleG2();
        emit returnSettleRes(fiveNum);
        reset();
    }

    // 结算r1
    function settleBegin() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint k = 0; k < R1Choose[player[i]].length; k++) {
                for (uint kk = 0; kk < R1Choose[player[i]][k].betArr.length; kk++) {
                    if (R1Choose[player[i]][k].betArr[kk] == fiveNum[0]) {
                        transferCoin(player[i], limit * 6.5 ether);
                    }
                }
            }
        }
        settleR2();
    }
    // 结算r2
    function settleR2() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < R2Choose[player[i]].length; j++) {
                uint notes = 0;
                for (uint k = 0; k < R2Choose[player[i]][j].betArr.length; k++) {
                    for (uint l = 0; l < fiveNum.length; l++) {
                        if (R2Choose[player[i]][j].betArr[k] == fiveNum[l]) {
                            notes++;
                        }
                    }
                }
                if (notes > 1) {
                    transferCoin(player[i], getNotes(notes, 2) * limit * 3 ether);
                }
            }
        }
        settleR3();
    }
    // 结算r3
    function settleR3() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < R3Choose[player[i]].length; j++) {
                uint notes = 0;
                for (uint k = 0; k < R3Choose[player[i]][j].betArr.length; k++) {
                    for (uint l = 0; l < fiveNum.length; l++) {
                        if (R3Choose[player[i]][j].betArr[k] == fiveNum[l]) {
                            notes++;
                        }
                    }
                }
                if (notes > 2) {
                    transferCoin(player[i], getNotes(notes, 3) * limit * 9.5 ether);
                }
            }
        }
        settleR4();
    }
    // 结算r4
    function settleR4() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < R4Choose[player[i]].length; j++) {
                uint notes = 0;
                for (uint k = 0; k < R4Choose[player[i]][j].betArr.length; k++) {
                    for (uint l = 0; l < fiveNum.length; l++) {
                        if (R4Choose[player[i]][j].betArr[k] == fiveNum[l]) {
                            notes++;
                        }
                    }
                }
                if (notes > 3) {
                    transferCoin(player[i], getNotes(notes, 4) * limit * 39 ether);
                }
            }
        }
        settleR5();
    }
    // 结算r5
    function settleR5() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < R5Choose[player[i]].length; j++) {
                uint notes = 0;
                for (uint k = 0; k < R5Choose[player[i]][j].betArr.length; k++) {
                    for (uint l = 0; l < fiveNum.length; l++) {
                        if (R5Choose[player[i]][j].betArr[k] == fiveNum[l]) {
                            notes++;
                        }
                    }
                }
                if (notes == 5) {
                    transferCoin(player[i], limit * 270 ether);
                }
            }
            for (uint m = 0; m < R6Choose[player[i]].length; m++) {
                uint notes2 = 0;
                for (uint n = 0; n < R6Choose[player[i]][m].betArr.length; n++) {
                    for (uint o = 0; o < fiveNum.length; o++) {
                        if (R6Choose[player[i]][m].betArr[n] == fiveNum[o]) {
                            notes2++;
                        }
                    }
                }
                if (notes2 == 5) {
                    transferCoin(player[i], limit * 45 ether);
                }
            }
        }
        settleR7();
    }
    // 结算r7-r8
    function settleR7() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < R7Choose[player[i]].length; j++) {
                uint notes = 0;
                for (uint k = 0; k < R7Choose[player[i]][j].betArr.length; k++) {
                    for (uint l = 0; l < fiveNum.length; l++) {
                        if (R7Choose[player[i]][j].betArr[k] == fiveNum[l]) {
                            notes++;
                        }
                    }
                }
                if (notes == 5) {
                    transferCoin(player[i], limit * 13 ether);
                }
            }
            for (uint m = 0; m < R8Choose[player[i]].length; m++) {
                uint notes1 = 0;
                for (uint o = 0; o < R8Choose[player[i]][m].betArr.length; o++) {
                    for (uint n = 0; n < fiveNum.length; n++) {
                        if (R8Choose[player[i]][m].betArr[o] == fiveNum[n]) {
                            notes1++;
                        }
                    }
                }
                if (notes1 == 5) {
                    transferCoin(player[i], limit * 4.5 ether);
                }
            }
        }
        settleZ2();
    }
    // 结算z2-z3
    function settleZ2() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < Z2Choose[player[i]].length; j++) {
                if ((Z2Choose[player[i]][j].betArr[0] == fiveNum[0])
                    && (Z2Choose[player[i]][j].betArr[1] == fiveNum[1])) {
                    transferCoin(player[i], limit * 65 ether);
                }
            }
            for (uint k = 0; k < Z3Choose[player[i]].length; k++) {
                if ((Z3Choose[player[i]][k].betArr[0] == fiveNum[0])
                && (Z3Choose[player[i]][k].betArr[1] == fiveNum[1])
                    && (Z3Choose[player[i]][k].betArr[2] == fiveNum[2])) {
                    transferCoin(player[i], limit * 585 ether);
                }
            }
        }
        settleG2();
    }
    // 结算g2
    function settleG2() private {
        for (uint i = 0; i < player.length; i++) {
            for (uint j = 0; j < G2Choose[player[i]].length; j++) {
                uint notes = 0;
                for (uint k = 0; k < G2Choose[player[i]][j].betArr.length; k++) {
                    if (G2Choose[player[i]][j].betArr[k] == fiveNum[0]) {
                        notes++;
                    }
                    if (G2Choose[player[i]][j].betArr[k] == fiveNum[1]) {
                        notes++;
                    }
                }
                if (notes == 2) {
                    transferCoin(player[i], limit * 32.5 ether);
                }
            }
            for (uint l = 0; l < G3Choose[player[i]].length; l++) {
                uint x2 = 0;
                for (uint m = 0; m < G3Choose[player[i]][l].betArr.length; m++) {
                    if (G3Choose[player[i]][l].betArr[m] == fiveNum[0]) {
                        x2++;
                    }
                    if (G3Choose[player[i]][l].betArr[m] == fiveNum[1]) {
                        x2++;
                    }
                    if (G3Choose[player[i]][l].betArr[m] == fiveNum[2]) {
                        x2++;
                    }
                }
                //                if (x2 == 3) {
                //                    transferCoin(player[i], limit * 97.5 ether);
                //                }
            }
        }
    }

    /**
     * 计算Cnr
     */
    function getNotes(uint n, uint r) private pure returns (uint){
        return n < r ? 0 : factorial(n) / factorial(r) / factorial(n - r);
    }
    /**
     * 阶乘
     */
    function factorial(uint num) private pure returns (uint){
        if (num < 0) {
            return 0;
        } else if (num == 0 || num == 1) {
            return 1;
        } else {
            for (uint i = num - 1; i >= 1; i--) {
                num *= i;
            }
        }
        return num;
    }

    /*
    * 生成最终5个数
    */
    function getResultFive() public constant returns (uint[5]){
        getFiveNum();
        getUniqueNum();
        return fiveNum;
    }
    /*
    * 生成5个可能重复的数
    */
    function getFiveNum() private {
        uint a = getXorPerson(returnXorNum(), 0, 2) % 11 + 1;
        uint b = getXorPerson(returnXorNum(), 2, 2) % 11 + 1;
        uint c = getXorPerson(returnXorNum(), 4, 2) % 11 + 1;
        uint d = getXorPerson(returnXorNum(), 6, 2) % 11 + 1;
        uint e = getXorPerson(returnXorNum(), 8, 2) % 11 + 1;
        fiveNum = [a, b, c, d, e];
    }

    /*
    * 得到独一无二的5个数
    */
    function getUniqueNum() private {
        bool thisFlag = false;
        for (uint i = 0; i < 5; i++) {
            for (uint j = i + 1; j < 5; j++) {
                if (fiveNum[i] == fiveNum[j]) {
                    thisFlag = true;
                    fiveNum[j]++;
                    if (fiveNum[j] > 11) {
                        fiveNum[j] -= 11;
                    }
                    break;
                }
            }
            if (thisFlag) {
                break;
            }
        }
        if (thisFlag) {
            getUniqueNum();
        }
    }
    /*
    * 让用户传入的随机数与合约内部的随机数异或，得到新随机
    */
    function returnXorNum() private view returns (uint){
        uint xorNum;
        for (uint i = 0; i < randomNum.length; i++) {
            xorNum = xorNum ^ randomNum[i];
        }
        return xorNum ^ (uint256(keccak256(block.difficulty, now)) % 1000000000);
    }

    // 截取随机数
    function getXorPerson(uint number, uint start, uint long) private pure returns (uint) {
        return (number / (10 ** start)) % (10 ** long);
    }
    // 比较字符串是否相等
    function stringsEqual(string memory _a, string memory _b) internal pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        for (uint i = 0; i < a.length; i ++)
            if (a[i] != b[i])
                return false;
        return true;
    }
    //重置函数，每一局结算后重置
    function reset() private {
        totalCoins = 0;
        randomNum.length = 0;
        for (uint i = 0; i < player.length; i++) {
            R1Choose[player[i]].length = 0;
            R2Choose[player[i]].length = 0;
            R3Choose[player[i]].length = 0;
            R4Choose[player[i]].length = 0;
            R5Choose[player[i]].length = 0;
            R6Choose[player[i]].length = 0;
            R7Choose[player[i]].length = 0;
            R8Choose[player[i]].length = 0;
            Z2Choose[player[i]].length = 0;
            Z3Choose[player[i]].length = 0;
            G2Choose[player[i]].length = 0;
            G3Choose[player[i]].length = 0;
        }
        player.length = 0;
        fiveNum = [0, 0, 0, 0, 0];
    }

    // 提现函数,只有创建者账户可以提现 todo 现在是全提
    function drawings() public payable {
        if (msg.sender == creator) {
            uint _balance = getCurrentBalance();
            transferCoin(creator, _balance);
        }
    }
}