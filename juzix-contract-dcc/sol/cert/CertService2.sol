pragma solidity ^0.4.2;

import "../permission/OperatorPermission.sol";
import "./CertServiceFeeModule.sol";

contract CertService2 is OperatorPermission {

    mapping(address => Checkpoint[]) datas;

    Order[] orders;

    enum Status {INVALID, APPLIED, PASSED, REJECTED, DISCARDED, REVOKED}

    event orderUpdated(address indexed applicant, uint256 indexed orderId, Status status);

    struct Order {

        address applicant;

        Status status;

        Content content;
    }

    struct Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint256 fromBlock;

        uint256 dataVersion;

        // `value`
        Content value;

    }

    struct Content {

        bytes digest1;

        bytes digest2;

        uint256 expired;

    }

    bytes public name;

    CertServiceFeeModule  certServiceFeeModule;

    function setCertServiceFeeModuleAddress(address certServiceFeeModuleAddress) public{
        onlyOwner();
        certServiceFeeModule=CertServiceFeeModule(certServiceFeeModuleAddress);
     }

    function CertService2(bytes _name) public {
        register("CertService2Module", "0.0.1.0", "CertService2", "0.0.1.0");
        name=_name;
        insertOrder(address(0), Status.INVALID, Content("", "", 0));
    }


    function apply() public returns (uint256 _orderId){
        certServiceFeeModule.apply();
        return insertOrder(msg.sender, Status.APPLIED, Content("", "", 0));

    }

    function insertOrder(address applicant, Status intialStatus, Content icc) internal returns (uint256 _orderId){
        //订单号=数组长度-1
        uint256 orderId = orders.push(Order(applicant, intialStatus, icc)) - 1;
        orderUpdated(applicant, orderId, intialStatus);
        return orderId;
    }

    function revoke(address applicant) public returns (uint256 _orderId) {
        if(!(applicant != address(0))){
            throw;
        }
        onlyOperator();
        Checkpoint memory cp = getCheckpointAt(applicant);

        //表示有有效的验证信息
        if(!(cp.value.digest1.length > 0)){
            log("!(cp.value.digest1.length > 0)");
            throw;
        }

        //插入订单
        Content memory icc = Content("", "", 0);
        uint256 orderId = insertOrder(applicant, Status.REVOKED, icc);

        //压栈
        appendElement(datas[applicant], orderId, icc);

        return orderId;
    }

    function pass(uint256 orderId,bytes digest1, bytes digest2,uint256 expired) public  {
        onlyOperator();

        if(!(expired > 0)){
            log("!(expired > 0)");
            throw;
        }

        if(!(digest1.length > 0 && digest1.length <= 100)){
            log("!(digest1.length > 0 && digest1.length <= 100)");
            throw;
        }
        if(!(digest2.length >= 0 && digest2.length <= 100)){
            log("!(digest2.length > 0 && digest2.length <= 100)");
            throw;
        }
        audit(orderId, Status.PASSED,digest1,digest2,expired);

    }

    function reject(uint256 orderId,bytes digest1, bytes digest2,uint256 expired) public  {
        onlyOperator();

        if(!(expired > 0)){
            log("!(expired > 0)");
            throw;
        }

        if(!(digest1.length > 0 && digest1.length <= 100)){
            log("!(digest1.length > 0 && digest1.length <= 100)");
            throw;
        }

        if(!(digest2.length >= 0 && digest2.length <= 100)){
            log("!(digest2.length > 0 && digest2.length <= 100)");
            throw;
        }

        audit(orderId, Status.REJECTED,digest1,digest2,expired);

    }


    function audit(uint256 orderId, Status result,bytes digest1, bytes digest2,uint256 expired) internal {
        if(!(orderId < orders.length)){
            log("!(orderId < orders.length)");
            throw;
        }
        if(!(result == Status.PASSED || result == Status.REJECTED)){
            log("!(result == Status.PASSED || result == Status.REJECTED)");
            throw;
        }

        Order storage order = orders[orderId];

         Content content=order.content;

         content.digest1=digest1;

         content.digest2=digest2;

         content.expired=expired;

        if(!(order.status == Status.APPLIED)){
            log("!(order.status == Status.APPLIED)");
            throw;
        }

        Checkpoint memory cp = getCheckpointAt(order.applicant);

        //检查身份验证数据版本
        if (orderId < cp.dataVersion) {
            changeStatus(order, orderId, Status.DISCARDED);
            return;
        }

        //查询验证结果
        if (result == Status.REJECTED) {
            changeStatus(order, orderId, Status.REJECTED);
            return;
        }

        //订单设置通过
        changeStatus(order, orderId, Status.PASSED);

        //压栈
        appendElement(datas[order.applicant], orderId, order.content);

    }

    function changeStatus(Order storage order, uint256 orderId, Status nextStatus) internal {
        order.status = nextStatus;
        orderUpdated(order.applicant, orderId, nextStatus);
    }


    function appendElement(Checkpoint[] storage checkpointList, uint256 dataVersion, Content memory icd) internal returns (uint256) {
        uint256 length = checkpointList.push(Checkpoint(block.number, dataVersion, icd));
        return length - 1;
    }




    function getCheckpointAt(Checkpoint[] storage checkpointList, uint _block) internal constant returns (Checkpoint) {
        if (checkpointList.length == 0) {
            return Checkpoint(0, 0, Content("", "", 0));
        }

        // Shortcut for the actual value
        if (_block >= checkpointList[checkpointList.length - 1].fromBlock)
            return checkpointList[checkpointList.length - 1];
        if (_block < checkpointList[0].fromBlock) {
            return Checkpoint(0, 0, Content("", "", 0));
        }

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpointList.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpointList[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpointList[min];
    }

    function getCheckpointAt(address _owner) internal constant returns (Checkpoint){
        return getCheckpointAt(datas[_owner], block.number);
    }

    function getDataAt(address _owner, uint256 _atBlock) constant public returns (bytes digest1, bytes digest2, uint256 expired, uint256 dataVersion) {
        Checkpoint memory cp = getCheckpointAt(datas[_owner], _atBlock);
        return (cp.value.digest1, cp.value.digest2, cp.value.expired, cp.dataVersion);
    }

    function getData(address _owner) constant public returns (bytes digest1, bytes digest2, uint256 expired, uint256 dataVersion) {
        return getDataAt(_owner, block.number);
    }

    function getData() constant public returns (bytes digest1, bytes digest2, uint256 expired, uint256 dataVersion) {
        return getData(msg.sender);
    }

    function getOrder(uint256 _orderId) constant public returns (address applicant, Status status, bytes digest1, bytes digest2, uint256 expired) {
        Order memory rf = orders[_orderId];
        return (rf.applicant, rf.status, rf.content.digest1, rf.content.digest2, rf.content.expired);
    }

    function getOrderLength() constant public returns (uint256 length) {
        return orders.length;
    }

}
