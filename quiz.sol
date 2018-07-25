pragma solidity ^0.4.0;

contract Quiz {
    string public contractName;
    uint public gameType = 2;
    address public creator = msg.sender;
    uint public creationTime;
    uint public historyTotalCoins = 0; // 历史下注总额

    uint public liveId;//赛事ID
    string homeTeam; //主队
    string visitingTeam; //客队
    uint oddsH; //主胜赔率
    uint oddsD; //平赔率
    uint oddsV; //客胜赔率
    uint deadline; // 截止日期
    uint singleBetCoin; //单注金额
    uint hConcedePoints = 0; //主队让球
    uint vConcedePoints = 0; //客队让球
    address [] hVictory;  // 保存选主胜0的地址
    mapping(address => uint) hVictoryMap; // 选主胜用户的下注金额
    address [] vVictory;   // 保存客胜1的地址
    mapping(address => uint) vVictoryMap; // 选客胜用户的下注金额
    address [] draw;    // 保存选平2的地址
    mapping(address => uint) drawMap; // 选平局用户的下注金额
    uint256 public availableBalance = 0;

    event returnBetResult(uint code, string msg, uint hCore, uint vCore); // 返回是否下注成功 101-"已过下注截止时间" 201-"下注成功" 205-"结算完成"

    function deposit() public payable {
        uint balance = getCurrentBalance();
        availableBalance = availableBalance + balance;
    }

    function getPublicData() public constant returns (string, uint, address, uint, uint){
        return (contractName, gameType, creator, creationTime, historyTotalCoins);
    }

    function getNow() public constant returns (uint){//获取当前时间
        uint Now = block.timestamp * 1000;
        return Now;
    }

    /*
    * @homeTeam 主队
    * @visitingTeam 客队
    * @oddsH 主胜赔率 0
    * @oddsD 平赔率   2
    * @oddsV 客胜赔率 1
    * solidity里面不支持小数计算
    * 传入的赔率扩大了100倍，最后的结果需要除以100
    */
    constructor(string _name, string _homeTeam, string _visitingTeam, uint _oddsH, uint _oddsD, uint _oddsV, uint _deadline, uint _singleCoin, uint _hConcedePoints, uint _vConcedePoints, uint _liveId) public{
        contractName = _name;
        homeTeam = _homeTeam;
        visitingTeam = _visitingTeam;
        oddsH = _oddsH;
        oddsD = _oddsD;
        oddsV = _oddsV;
        deadline = _deadline;
        singleBetCoin = _singleCoin;
        hConcedePoints = _hConcedePoints;
        vConcedePoints = _vConcedePoints;
        liveId = _liveId;
        creationTime = getTimestamp();
    }

    function getLiveId() returns(uint){
        return liveId;
    }

    // 获取当前出块时间戳 (单位是秒)
    function getTimestamp() public constant returns (uint) {
        return block.timestamp;
    }
    // 返回当前合约账户的余额
    function getCurrentBalance() public constant returns (uint256) {
        return address(this).balance;
    }

    // 返回配置参数
    function getSetting() public constant returns (uint, string, string, string, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (gameType, contractName, homeTeam, visitingTeam, oddsH, oddsD, oddsV, deadline, singleBetCoin, hConcedePoints, vConcedePoints, liveId);
    }

    // 下注函数
    /*
    * @addr 下注地址
    * @choose 选择胜负平 ------- 0 1 2 , -1 代表没有选
    * @coin 下注金额
    * @num 下注数 ------- 1 2 3
    */
    function betFun(address addr, uint [3] choose, uint coin, uint num, uint maximum) public payable {
        if (block.timestamp * 1000 > deadline) {
            transferCoin(addr, coin);
            emit returnBetResult(101, "已过下注截止时间", 0, 0);
        } else {
            //            emit returnBetResult(201, "下注成功", 0, 0);
            historyTotalCoins += coin;
            for (uint i = 0; i < 3; i++) {
                if (choose[i] == 0) {
                    bool flag1 = false;
                    for (uint j = 0; j < hVictory.length; j++) {
                        if (hVictory[j] == addr) {
                            flag1 = true;
                            break;
                        }
                    }
                    if (!flag1) {
                        hVictory.push(addr);
                    }
                    hVictoryMap[addr] = hVictoryMap[addr] + coin / num;
                } else if (choose[i] == 1) {
                    bool flag2 = false;
                    for (uint k = 0; k < vVictory.length; k++) {
                        if (vVictory[k] == addr) {
                            flag2 = true;
                            break;
                        }
                    }
                    if (!flag2) {
                        vVictory.push(addr);
                    }
                    vVictoryMap[addr] = vVictoryMap[addr] + coin / num;
                } else if (choose[i] == 2) {
                    bool flag3 = false;
                    for (uint l = 0; l < draw.length; l++) {
                        if (draw[l] == addr) {
                            flag3 = true;
                            break;
                        }
                    }
                    if (!flag3) {
                        draw.push(addr);
                    }
                    drawMap[addr] = drawMap[addr] + coin / num;
                }
            }
            availableBalance = availableBalance + coin - maximum;
            //奖池可用余额 = 当前可用余额 + 下注总金额 - 最大奖金
        }
    }

    // 结算函数
    // @_result 传入谁赢 0 1 2 / 主胜 客胜 平
    function getResult(uint _hCore, uint _vCore) public {
        uint h = _hCore + vConcedePoints;
        //主队得分+让球分数
        uint v = _vCore + hConcedePoints;
        //客队得分+让球分数
        if (h > v) {
            for (uint i = 0; i < hVictory.length; i++) {
                transferCoin(hVictory[i], hVictoryMap[hVictory[i]] * oddsH / 100);
            }
        }
        if (h < v) {
            for (uint j = 0; j < vVictory.length; j++) {
                transferCoin(vVictory[j], vVictoryMap[vVictory[j]] * oddsV / 100);
            }
        }
        if (h == v) {
            for (uint k = 0; k < draw.length; k++) {
                transferCoin(draw[k], drawMap[draw[k]] * oddsD / 100);
            }
        }
        emit returnBetResult(205, "比赛结束", _hCore, _vCore);
        reset();
        //        if (block.timestamp * 1000 > deadline) {
        //            drawings();
        //            reset();
        //        }
    }

    // 提现函数,只有创建者账户可以提现
    function drawings(uint _coin) public payable {
        if (msg.sender == creator) {
            uint _balance = getCurrentBalance();
            transferCoin(creator, _balance);
        }
    }

    // 重置函数
    function reset() private {
        for (uint i = 0; i < hVictory.length; i++) {
            hVictoryMap[hVictory[i]] = 0;
        }
        hVictory.length = 0;
        for (uint j = 0; j < vVictory.length; j++) {
            vVictoryMap[vVictory[j]] = 0;
        }
        vVictory.length = 0;
        for (uint k = 0; k < draw.length; k++) {
            drawMap[draw[k]] = 0;
        }
        draw.length = 0;
    }

    // 转账函数
    /*
    * @_to 目标地址
    * @_coins 金额
    */
    function transferCoin(address _to, uint _coins) private {
        _to.transfer(_coins);
    }
}
