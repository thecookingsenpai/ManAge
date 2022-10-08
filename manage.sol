// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

contract protected {
    // SECTION User management
    struct USER {
        string name;
        string username;
        string email;
        string notes;
    }

    mapping (address => USER) users;
    // Levels:
    // 0: None
    // 1: Admin
    mapping(address => uint) access_level;

    modifier accessControl(uint level_required) {
        require(access_level[msg.sender] <= level_required, "access denied");
        _;
    }

    // !SECTION User management

    mapping (address => bool) is_admin;
    function admin_privilege(address addy) public view returns(bool) {
        return is_admin[addy];
    }
    function set_admin_privilege(address addy, bool booly) public onlyAdmin {
        is_admin[addy] = booly;
        // Setting admin access level
        if(booly) {
            access_level[addy] = 1;
        } else {
            if (access_level[addy] == 1) {
                access_level[addy] = 0;
            }
        }
    }
    modifier onlyAdmin() {
        require( is_admin[msg.sender] || 
                 access_level[msg.sender] == 1 ||
                 msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAdmin {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

// SECTION Main contract

contract manAge is protected {

    // SECTION Structs definition

    // SECTION Employees management
    struct ROLE {
        string description;
    }

    mapping (string => ROLE) roles;

    struct EMPLOYEE {
        string name;
        string role;
        uint256 salary;
    }

    mapping(address => EMPLOYEE) employees;
    // !SECTION Employees management

    // SECTION Company management
    struct COMPANY {
        string name;
        string description;
        string website;
        string logo;
    }

    COMPANY company;
    // !SECTION Company management

    // SECTION Products management

    struct ITEM {
        uint product_id;
        ITEM_POSITION position;
        ITEM_STATUS status;
    }

    struct PRODUCT {
        string name;
        string description;
        uint256 price;
        uint256 stock;
        uint256 position;
        mapping(uint => ITEM) items;
        uint256 item_count;
    }

    mapping (string => PRODUCT) products;
    mapping (uint256 => string) product_ids;
    mapping (string => uint256) product_names;
    uint256 product_count;

    // !SECTION Products management

    // SECTION Positions management
    struct ITEM_POSITION {
        string description;
        uint access_level;
        uint[] products_list;
    }
    // Product -> Item -> Position
    mapping(uint => mapping(uint => ITEM_POSITION)) positions; 

    struct ITEM_STATUS {
        string description;
    }
    // Product -> Item -> Status
    mapping(uint => mapping(uint => ITEM_STATUS)) statuses; 

    // !SECTION Positions management

    // SECTION Orders management
    struct ORDER {
        string product;
        uint256 quantity;
        uint256 price;
        uint256 date;
    }

    mapping (uint256 => ORDER) orders;
    mapping (uint256 => uint256) order_status;
    mapping (address => uint256[]) customer_orders;

    // !SECTION Orders management

    // SECTION Customers management
    struct CUSTOMER {
        string name;
        string email;
        string phone;
        string direction;
    }

    mapping (address => CUSTOMER) customers;
    // !SECTION Customers management

    // SECTION Transport documents
    struct POSITION {
        string city;
        string country;
        string direction;
        string postal_code;
        string referent;
        uint telephone_number;
        uint cohord_x;
        uint cohord_y;
    }

    struct TRANSPORT_STATE {
        string description;
    }

    struct TRANSPORT_DOCUMENT {
        string name;
        string description;
        address customer;
        uint date_placed;
        uint date_shipped;
        uint date_delivered;
        POSITION actual_position;
        TRANSPORT_STATE actual_state;
        string notes;
    }
    mapping (uint256 => TRANSPORT_DOCUMENT) transport_documents;
    // !SECTION Transport documents

    // SECTION Assignments
    struct ASSIGNMENT {
        string name;
        string description;
        uint256 date;
        uint256 deadline;
        string status;
        string task;
        bool opened;
    }

    mapping (uint256 => ASSIGNMENT) assignments;
    uint assignment_count;
    mapping (address => uint256[]) employee_assignments;
    // !SECTION Assignments

    // !SECTION Structs definition

    // ANCHOR Constructor
    constructor() {
        owner = msg.sender;
        is_admin[msg.sender] = true;
    }
    
    // SECTION Methods to manage types
    function set_company(string memory _name,
                         string memory _description,
                        string memory _website,
                        string memory _logo) public onlyAdmin {
        company.name = _name;
        company.description = _description;
        company.website = _website;
        company.logo = _logo;
    }

    function get_company() public view returns (string memory,
                                                string memory,
                                                string memory,
                                                string memory) {
        return (company.name,
                company.description,
                company.website,
                company.logo);
    }

    function set_role(string memory _role,
                      string memory _description) public onlyAdmin {
        roles[_role].description = _description;
    }

    function get_role(string memory _role) public view returns (string memory) {
        return roles[_role].description;
    }

    function set_employee(address _employee,
                          string memory _name,
                          string memory _role,
                          uint256 _salary) public onlyAdmin {
        employees[_employee].name = _name;
        employees[_employee].role = _role;
        employees[_employee].salary = _salary;
    }

    function get_employee(address _employee) public view returns (string memory,
                                                                 string memory,
                                                                 uint256) {
        return (employees[_employee].name,
                employees[_employee].role,
                employees[_employee].salary);
    }

    function get_employee_acl( address _employee) public view
                                returns (uint) {
        return access_level[_employee];
    }

    function set_product(string memory _id,
                         string memory _name,
                         string memory _description,
                         uint256 _price,
                         uint256 _stock) public onlyAdmin {
        products[_id].name = _name;
        products[_id].description = _description;
        products[_id].price = _price;
        products[_id].stock = _stock;
        product_ids[product_count] = _id;
        product_count++;
    }

    function get_product(string memory _id) public view returns (string memory,
                                                                string memory,
                                                                uint256,
                                                                uint256) {
        return (products[_id].name,
                products[_id].description,
                products[_id].price,
                products[_id].stock);
    }

    function set_status(uint256 _product,
                        uint256 _item,
                        string memory _description) public onlyAdmin {
        products[product_ids[_product]].items[_item].status.description = _description;
    }

    function get_status(uint256 _product,
                        uint256 _item) public view returns (ITEM_STATUS memory) {
        return products[product_ids[_product]].items[_item].status;
    }

    function set_customer(address _customer,
                          string memory _name,
                          string memory _email,
                          string memory _phone,
                          string memory _direction) public onlyAdmin {
        customers[_customer].name = _name;
        customers[_customer].email = _email;
        customers[_customer].phone = _phone;
        customers[_customer].direction = _direction;
    }

    function get_customer(address _customer) public view returns (string memory,
                                                                 string memory,
                                                                 string memory,
                                                                 string memory) {
        return (customers[_customer].name,
                customers[_customer].email,
                customers[_customer].phone,
                customers[_customer].direction);
    }

    function set_order(address _customer,
                       string memory _product,
                       uint256 _quantity,
                       uint256 _price,
                       uint256 _date) public onlyAdmin {
        orders[product_count].product = _product;
        orders[product_count].quantity = _quantity;
        orders[product_count].price = _price;
        orders[product_count].date = _date;
        customer_orders[_customer].push(product_count);
        product_count++;
    }

    function get_order(uint256 _order) public view returns (string memory,
                                                           uint256,
                                                           uint256,
                                                           uint256) {
        return (orders[_order].product,
                orders[_order].quantity,
                orders[_order].price,
                orders[_order].date);
    }

    function get_customer_orders(address _customer) public view returns (uint256[] memory) {
        return customer_orders[_customer];
    }

    function set_order_status(uint256 _order,
                              uint256 _status) public onlyAdmin {
        order_status[_order] = _status;
    }

    function get_order_status(uint256 _order) public view returns (uint256) {
        return order_status[_order];
    }

    function set_assignment(string memory _name,
                            string memory _description,
                            uint256 _date,
                            uint256 _deadline,
                            string memory _status,
                            string memory _task,
                            bool _opened) public onlyAdmin {
        assignments[assignment_count].name = _name;
        assignments[assignment_count].description = _description;
        assignments[assignment_count].date = _date;
        assignments[assignment_count].deadline = _deadline;
        assignments[assignment_count].status = _status;
        assignments[assignment_count].task = _task;
        assignments[assignment_count].opened = _opened;
        assignment_count++;
    }

    function get_assignment(uint256 _assignment) public view returns (string memory,
                                                                     string memory,
                                                                     uint256,
                                                                     uint256,
                                                                     string memory,
                                                                     string memory,
                                                                     bool) {
        return (assignments[_assignment].name,
                assignments[_assignment].description,
                assignments[_assignment].date,
                assignments[_assignment].deadline,
                assignments[_assignment].status,
                assignments[_assignment].task,
                assignments[_assignment].opened);
    }

    function assign_to_employee(uint256 _assignment,
                                address _employee) public onlyAdmin 
                                returns (uint){
         uint assignment_id = employee_assignments[_employee].length;
         employee_assignments[_employee].push(_assignment);
         return assignment_id;
    }

    function get_employee_assignments(address _employee) public view returns (uint256[] memory) {
        return employee_assignments[_employee];
    }

    function get_single_employee_assignment(address _employee,
                                            uint256 _assignment) public view returns (uint256) {
        return employee_assignments[_employee][_assignment];
    }

    function set_assignment_status(uint256 _assignment,
                                   string memory _status) public onlyAdmin {
        assignments[_assignment].status = _status;
    }

    function get_assignment_status(uint256 _assignment) public view returns (string memory) {
        return assignments[_assignment].status;
    }

    function add_item_to_product(string memory _product) public onlyAdmin 
                                 returns (uint256){
        uint256 _product_id = product_names[_product];
        products[_product].items[products[_product].item_count].product_id = _product_id;
        products[_product].item_count++;
        return products[_product].item_count;
    }

    function get_item_from_product(string memory _product,
                                   uint256 _item) public view returns (ITEM memory) {
        return products[_product].items[_item];
    }

    function set_item_status(string memory _product,
                             uint256 _item,
                             string memory _description) public onlyAdmin {
        products[_product].items[_item].status.description = _description;
    }

    function get_item_status(string memory _product,
                             uint256 _item) public view returns (ITEM_STATUS memory) {
        return products[_product].items[_item].status;
    }

    // TODO Check what is to insert more

    // !SECTION Methods to manage types

    // SECTION Administrative methods
    function set_access_level(uint256 _access,
                              address _user) public accessControl(_access) {
        access_level[_user] = _access;
    }

    function get_access_level(address _user) public view returns (uint256) {
        return access_level[_user];
    }

    // !SECTION Administrative methods
}

// !SECTION Main contract