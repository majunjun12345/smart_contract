pragma solidity ^0.4.20;

contract CrowdFunding {
    
    // 赞助人 赞助人地址 和 赞助金额
    struct Funder {
        address addr;
        uint amount;
    }

    // 运动员 运动员地址 募捐总额 赞助人数 已赞助金额 按照索引存储赞助人信息
    struct Campaign {
        address beneficiary;
        uint fundingGoal;
        uint numFunders;
        uint amount;
        mapping (uint => Funder) funders;
    }

    // 统计运动员人数，以及建立根据 id 建立运动员映射关秀
    uint public numCampaigns;
    mapping (uint => Campaign) campaigns;

    // 新增一个 运动员，初始化结构体，建立 ID 的映射关系
    function newCampaign (address beneficiary, uint fundingGoal) public returns (uint campaignID) {
        campaignID = numCampaigns++;
        campaigns[campaignID] = Campaign(beneficiary, fundingGoal, 0, 0);
    }

    // 赞助人输入运动员对应的编号即可赞助  payable
    function contribute(uint campaignID) public payable {
        // 这里为什么要用到 storage?
        Campaign storage c = campaigns[campaignID];
        c.funders[c.numFunders++] = Funder({addr: msg.sender, amount: msg.value});
        c.amount += msg.value;
        c.beneficiary.transfer(msg.value); 
    }

    // 检查是否达到了赞助金额
    function chekGoalReached(uint campaignID) public view returns (bool reached) {
        // 这里为什么要用 storage
        // campaigns[campaignID] 是 storage 对象，c 默认是 memory 对象，不能将 storage 赋值给 momory
        Campaign storage c = campaigns[campaignID];
        if (c.amount < c.fundingGoal) 
            return false;
        return true;
    }

}