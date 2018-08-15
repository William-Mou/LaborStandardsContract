pragma solidity ^0.4.17;

contract Transaction {
    //定義勞方、資方
    address employee;
    address employer;
    //定義創見時間
    uint create_time;
    //定義基本薪資
    uint base_wage;
    //定義應付薪資
    uint payables;
    //定義修補期限
    uint expire = 8;
    //定義工作時數
    uint working_hours;
    //＊定義每 wei 兌台幣之轉換 
    uint ETH_to_TWD_100 = 3000000;
    //定義合約是否為合法合約
    bool legal = false;
    //定義補休假期限是否結束
    bool ended = false;
    
    
    event contract_status(
        address employer,
        address employee,
        bool legal,
        bool endeded,
        uint working_hours,
        uint amount
    );


    //建置初始化方法
    constructor(address new_employee, uint new_working_hours, uint new_base_wage )public payable {
        //導入變數
        employee = new_employee;
        employer = msg.sender;
        working_hours = new_working_hours;
        base_wage = new_base_wage;

        //依照勞基法坢段加班薪資
        if (working_hours >= 2) payables = (working_hours-2)*base_wage*266+working_hours*233*base_wage;
        else payables = working_hours*233*base_wage;

        //判斷薪資是否合格
        if (msg.value >= payables/ETH_to_TWD_100) legal = true;
        else return;
        create_time = block.timestamp;
    }

    //合約修改知函數（新增工作時數）同時傳入更多薪資
    function add_more(uint new_working_hours )public payable {
        //如果合約已結束，則回傳錯誤
        if (ended == true) revert(" end == true，合約已關閉");
        //否則導入函數
        working_hours += new_working_hours;

        //依勞基法判斷加班薪資
        if (working_hours >= 2) payables = (working_hours-2)*base_wage*266+working_hours*233*base_wage;
        else payables = working_hours*233*base_wage;
        
        //判斷薪資是否合格
        if (payables >= address(this).balance/ETH_to_TWD_100) legal = true;
        else revert("薪資過少");

        create_time = block.timestamp;
    }
    
    //若仍未休假，勞方領取加班費
    function collectMoney() public {
        //如果時間已經超過8週
        if ((block.timestamp - create_time) > (expire * 1 seconds)) {
            //設定補休假期結束
            ended = true;
        }
        //否則設定合約繼續
        else {
            ended = false;
        }

        //若申請者非勞方 或 合約尚未結束 或 合約不成立，則不執行
        if (msg.sender != employee || ended == false || legal == false) revert("申請者非勞方 或 合約尚未結束 或 合約不成立");
        employee.transfer(address(this).balance);
    }
    //若已經休假，勞方回傳押金給資方
    function returnMoney() public{
        //若申請者非勞方，或合約已結束，則不執行
        if (msg.sender != employee || ended == true) revert("您非勞方，或合約已到期，請申請 collectMoney 領取加班費");
        //否則，傳送押金給資方
        employer.transfer(address(this).balance);
    }

    function get_status() public{
        emit contract_status(
            employer,
            employee,
            legal,
            ended,
            working_hours,
            address(this).balance
        );
    }
}