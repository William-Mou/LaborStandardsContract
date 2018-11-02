pragma solidity ^0.4.10;

contract Transaction {
    //定義勞方、資方
    address public employee;
    address public employer;
    //定義創見時間
    uint public create_time;
    //定義基本薪資
    uint public base_wage;
    //定義應付薪資
    uint public payables;
    //定義補休期限
    uint public expire = 8 seconds;
    //定義工作時數
    uint public working_hours;
    //＊定義每 wei 兌台幣之轉換 6500
    uint public ETH_to_TWD_100 = 1538461538461;
    //定義已收金額
    uint public this_value = 0;
    //定義合約是否為合法合約
    bool public legal = false;
    //定義補休假期限是否結束
    bool public ended = false;
    
    
    event contract_status(
        address employer,
        address employee,
        bool legal,
        bool endeded,
        uint working_hours,
        uint amount
    );


    //建置初始化方法
    function Transaction(address new_employee, uint new_working_hours, uint new_base_wage )public payable {
        this_value = address(this).balance;
        //導入變數
        employee = new_employee;
        employer = msg.sender;
        working_hours = new_working_hours;
        base_wage = new_base_wage;

        //依照勞基法判斷加班薪資
        if (working_hours >= 2) {
            payables = (working_hours-2)*base_wage*266+working_hours*233*base_wage;
        }
        else {
            payables = working_hours*233*base_wage;
        }
        
        //判斷薪資是否合格

        require(msg.value*ETH_to_TWD_100 >= payables);
        legal = true;
        create_time = block.timestamp;
    }

    //合約修改知函數（新增工作時數）同時傳入更多薪資
    function add_more(uint new_working_hours )public payable {
        //如果時間已經超過8週
        if ((block.timestamp - create_time) > (expire * expire)) {
            //設定補休假期結束
            ended = true;
        }
        //否則設定合約繼續
        else {
            ended = false;
        }
        //如果合約已結束，則回傳錯誤
        require(ended != true);
        //否則新增時數
        working_hours += new_working_hours;
        this_value += address(this).balance;
        //依勞基法判斷加班薪資
        if (working_hours >= 2) {
            payables = (working_hours-2)*base_wage*266+working_hours*233*base_wage;
        }
        else {
            payables = working_hours*233*base_wage;
        }
        //判斷薪資是否合格
        require(payables*ETH_to_TWD_100 <= address(this).balance);
        legal = true;
        create_time = block.timestamp;
    }
    
    //若仍未休假，勞方領取加班費
    function collectMoney() public {
        //如果時間已經超過8週
        if ((block.timestamp - create_time) > (expire * expire)) {
            //設定補休假期結束
            ended = true;
        }
        //否則設定合約繼續
        else {
            ended = false;
        }

        //若申請者非勞方 或 合約尚未結束 或 合約不成立，則不執行
        require(msg.sender == employee && ended == true );
        employee.transfer(address(this).balance);
    }
    //若已經休假，勞方回傳押金給資方
    function returnMoney() public{
        //若申請者非勞方，或合約已結束，則不執行
        require(msg.sender == employee && ended == false && legal == true);
        //否則，傳送押金給資方
        employer.transfer(address(this).balance);
        ended = true;
        this_value = address(this).balance;
    }
}