CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_society` (
            `business_id` int AUTO_INCREMENT,
            `business_name` varchar(255) NOT NULL,
            `ledger` int(40) NOT NULL DEFAULT 0,
            `blip_hash` varchar(255) NOT NULL DEFAULT 'none',
            `show_blip` varchar(6) NOT NULL DEFAULT "true",
            `tax_amount` int(30) NOT NULL DEFAULT 0,
            `taxes_paid` char(6) NOT NULL DEFAULT "false",
            `inv_limit` int(30) NOT NULL DEFAULT 0,
            `coords` LONGTEXT NOT NULL,
            `inventory_upgrade_stages` LONGTEXT NOT NULL,
            `inventory_current_stage` int(40) NOT NULL DEFAULT 0,
            `webhook_link` varchar(255) NOT NULL DEFAULT "none",
            `owner_id` int(10) NOT NULL,
            `society_job` varchar(255) NOT NULL DEFAULT 'none',
            `max_job_grade` int NOT NULL DEFAULT 5,
            PRIMARY KEY (`business_id`),
            FOREIGN KEY (`owner_id`) REFERENCES `characters`(`charidentifier`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_society_employees` (
            `business_id` int NOT NULL,
            `employee_rank` varchar(100) NOT NULL DEFAULT "none",
            `employee_id` int(10) NOT NULL,
            `employee_name` varchar(255) NOT NULL,
            `employee_payment` int(11) NOT NULL DEFAULT 0,
            FOREIGN KEY (`business_id`) REFERENCES `bcc_society`(`business_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_society_ranks` (
            `business_id` int NOT NULL,
            `rank_name` varchar(255) NOT NULL,
            `rank_pay` int(30) NOT NULL,
            `rank_pay_increment` int(30) NOT NULL,
            `rank_can_toggle_blip` char(6) NOT NULL DEFAULT "false",
            `rank_can_withdraw` char(6) NOT NULL DEFAULT "false",
            `rank_can_deposit` char(6) NOT NULL DEFAULT "false",
            `rank_can_edit_ranks` char(6) NOT NULL DEFAULT "false",
            `rank_can_manage_employees` char(6) NOT NULL DEFAULT "false",
            `rank_can_open_inventory` char(6) NOT NULL DEFAULT "false",
            `rank_can_edit_webhook_link` char(6) NOT NULL DEFAULT "false",
            `rank_can_manage_store` char(6) NOT NULL DEFAULT "false",
            `society_job_rank` int NOT NULL DEFAULT 0,
            `rank_can_bill_players` char(6) NOT NULL DEFAULT "false",
            `rank_can_switch_job` char(6) NOT NULL DEFAULT "true",
            `rank_label` varchar(255) NOT NULL DEFAULT 'none',
            `employee_payment` int(11) NOT NULL DEFAULT 0,
            FOREIGN KEY (`business_id`) REFERENCES `bcc_society`(`business_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS bcc_society_bills (
        id INT AUTO_INCREMENT PRIMARY KEY,
        billed_identifier VARCHAR(255) NOT NULL,
        biller_identifier VARCHAR(255) NOT NULL,
        billed_name VARCHAR(150),
        biller_name VARCHAR(150),
        amount INT NOT NULL,
        society_id VARCHAR(255),
        description TEXT,
        timestamp INT NOT NULL
    );
    ]])
    -- Check if column already exists
    local result = MySQL.query.await([[
        SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'bcc_society_bills' 
        AND COLUMN_NAME = 'status'
    ]])

    if not result or #result == 0 then
        -- Add the column if it does not exist
        MySQL.query.await([[ 
            ALTER TABLE `bcc_society_bills` 
            ADD COLUMN `status` VARCHAR(10) DEFAULT 'PENDING';
        ]])
        print("[MySQL] Column 'status' added to bcc_society_bills ✅")
    else
        print("[MySQL] Column 'status' already exists in bcc_society_bills ⏩")
    end

    local switchColumn = MySQL.query.await([[
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'bcc_society_ranks'
        AND COLUMN_NAME = 'rank_can_switch_job'
    ]])

    if not switchColumn or #switchColumn == 0 then
        MySQL.query.await([[ 
            ALTER TABLE `bcc_society_ranks`
            ADD COLUMN `rank_can_switch_job` CHAR(6) NOT NULL DEFAULT 'true';
        ]])
        print("[MySQL] Column 'rank_can_switch_job' added to bcc_society_ranks ✅")
    else
        print("[MySQL] Column 'rank_can_switch_job' already exists in bcc_society_ranks ⏩")
    end
    DBUpdated = true
        -- Debug message for successful table creation or update
    print("Database table \x1b[35m\x1b[1m*bcc_society*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
end)
