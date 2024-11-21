# BCC-Society
> Welcome to **BCC-Society**, the ultimate script for managing societies in RedM! Thank you for your support!

## Features
- **Simple Configuration**: Easily customize your society setup.
- **Effortless Translations**: Translate the script into different languages with ease.
- **Highly Modular**: Each society is created with its own settings, minimizing the need for extensive configuration.
- **Admin Management Menu**: Conveniently manage your society through an intuitive menu.
- **Developer Exports**: Export data for further customization and analysis.
- **Webhooks**: Stay connected with society and admin updates through webhooks.
- **Safety and Security**: Built-in features ensure the safety and security of your society.
- **Seamless Experience**: No need to relog, except for society deletion.
- **Society Inventories**: Manage inventories for your society.
- **Upgradeable Inventories**: Set Upgrades for inventories during society creation, that players can buy in thier menu later.
- **Named Societies**: Give your society a unique name.
- **Togglable Blip**: Easily toggle the blip for your society.
- **Ledger System**: Keep track of society finances, store, and withdraw money with a ledger system.
- **Employee Management**: Hire and manage employees for your society.
- **Rank System**: Implement a rank system within your society.
- **Payment System**: Manage payments within your society.
- **Billing Command**: Easily handle billing within your society.
- **Taxes**: Implement a tax system within your society.
- **Version Checking**: Version Checking to keep you upto date!
- **Society Jobs**: Each society has its own job that you set during creation, or change in the admin menu. Job Grade is set for each society Rank so each rank has its own job grade that the owner or employee with the manage rank permission can set/change.
- **Toggle Society Jobs Duty**: Society jobs can be setup to allow for toggling being on and off duty(Not all jobs, just society jobs).

# Requirements:
- VORP CORE
- VORP INVENTORY
- BCC-Utils version 1.0.9 and above
- Feather Menu: https://github.com/FeatherFramework/feather-menu/releases
- VORP CHARACTER

# Society API

The Society API provides functionality for managing society data in a RedM environment. This API supports operations like retrieving society information, managing employees, handling society finances, and verifying job roles, offering a robust solution for society-related management.

## Setup

The `SocietyAPI` is globally accessible within the script and can be retrieved using:
```lua
exports("getSocietyAPI", function() return SocietyAPI end)
```

## Features

1. **Society Management**: Retrieve and manage society details, employees, ranks, and ledger information.
2. **Employee Management**: Manage employee roles, check rank permissions, and retrieve rank details.
3. **Financial Operations**: Add or deduct funds from the society ledger.
4. **Miscellaneous Functions**: Retrieve all societies a character owns or is employed in, list all societies, and verify player job status.

## API Methods

### Society Management

- **`SocietyAPI:GetSociety(societyId)`**  
  Retrieves a society object by its ID, which provides access to various functions for managing the society.

    ```lua
    local society = SocietyAPI:GetSociety(societyId)
    if society then
        local info = society:GetSocietyInfo()
        print(info)
    end
    ```

### Employee Management

- **`society:GetSocietyEmployees()`**  
  Fetches all employees associated with the society.

    ```lua
    local employees = society:GetSocietyEmployees()
    if employees then
        for _, employee in ipairs(employees) do
            print(employee.employee_name)
        end
    end
    ```

- **`society:CheckRankPermissions(rankName)`**  
  Checks the permissions for a given rank within the society.

    ```lua
    local rankInfo = society:CheckRankPermissions("Manager")
    if rankInfo then
        print("Permissions:", rankInfo.permissions)
    end
    ```

### Financial Management

- **`society:AddMoneyToLedger(amount)`**  
  Adds funds to the society's ledger.

    ```lua
    society:AddMoneyToLedger(1000)
    ```

- **`society:RemoveMoneyFromLedger(amount)`**  
  Deducts funds from the society's ledger.

    ```lua
    society:RemoveMoneyFromLedger(500)
    ```

### Miscellaneous Functions

- **`SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charIdentifier)`**  
  Retrieves all societies owned by a character.

    ```lua
    local ownedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charIdentifier)
    if ownedSocieties then
        for _, society in ipairs(ownedSocieties) do
            print(society.business_id, society.business_name)
        end
    end
    ```

- **`SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charIdentifier)`**  
  Fetches all societies where a character is employed.

    ```lua
    local employedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charIdentifier)
    if employedSocieties then
        for _, society in ipairs(employedSocieties) do
            print(society.business_id)
        end
    end
    ```

- **`SocietyAPI.MiscAPI:CheckIfPlayerHasJobAndIsOnDuty(jobName, playerSource)`**  
  Verifies if a player has a specific job and is currently on duty.

    ```lua
    local isOnDuty = SocietyAPI.MiscAPI:CheckIfPlayerHasJobAndIsOnDuty("Police", playerSource)
    print("Is On Duty:", isOnDuty)
    ```

## Example Usage

```lua
-- Retrieve a society and get its information
local society = SocietyAPI:GetSociety(1)
if society then
    print(society:GetSocietyInfo())

    -- Add funds to the ledger
    society:AddMoneyToLedger(500)

    -- Retrieve employees
    local employees = society:GetSocietyEmployees()
    if employees then
        for _, employee in ipairs(employees) do
            print(employee.employee_name)
        end
    end
end

-- Check all societies a character owns
local charIdentifier = 1234
local ownedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charIdentifier)
if ownedSocieties then
    for _, soc in ipairs(ownedSocieties) do
        print(soc.business_id, soc.business_name)
    end
end
```

The Society API streamlines society management, making it easier to handle society operations in RedM scripts.

## Special thanks
Thanks to Jake for the base of this script.