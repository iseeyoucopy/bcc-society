Config = {
    devMode = true,                             -- Enable/Disable Dev Mode (False on live)
    defaultlang = "en_lang",                    -- Choose the language file to use
    Notify = "feather-menu",                    ----or use vorp-core
    NotifyOptions = {
        type = "info",                          -- default type
        transition = "slide",                  -- bounce, flip, slide, zoom
        position = "top-center",                -- top-left, top-center, top-right, bottom-left, bottom-center, bottom-right
        autoClose = 5000,                       -- default duration in ms
        hideProgressBar = false,                -- show progress bar
    },
    createSocietyCommandName = "createSociety", -- Command to create a society
    useWebhooks = true,
    WebhookTitle = 'BCC-Society',
    WebhookAvatar = '',
    adminLogsWebhook = "", -- Webhook for admin logs
    -- TO BE ABLE TO RUN CREATE SOCIEITY YOUR USER GROUP MUST BE ADMIN IN VORP

    employeeWorksAtMultiple = true,                     -- Allow employees to work at multiple societies (Can only own one regardless of this setting)
    openJobManagementMenuCommandName = "jobManagement", -- Command to open the job management menu (This is how you switch between jobs (NOTE this only applies if you enable employeeWorksAtMultiple))
    switchJobCommandName = "switchjob",                 -- Command to switch directly to a specific job
    switchJobCooldownSeconds = 30,                       -- Cooldown for the switch job command in seconds (set to 0 to disable)

    adminGroups = { "admin", "superadmin" },  -- groups allowed
    AllowedJobs = { 'writer', 'societymanager' },
    toggleOnDutyCommandName = "onDuty",       -- Command to toggle duty
    toggleOffDutyCommandName = "offDuty",     -- Command to toggle duty
    allowBlips = true,                        -- Allow blips to be shown for societies
    toggleBlipCooldown = 10,                  -- Cooldown for toggling blips in seconds
    manageSocietyPromptKey = 0x4CC0E2FE,      -- Key to open the society management prompt
    taxesEnabled = true,                      -- Enable/Disable taxes
    taxDay = 26,                              -- Day of the month to collect taxes
    taxResetDay = 27,                         -- Make sure this is set to a valid date 1 day after the tax day
    openMenuRadius = 2,                       -- Radius to open the society management menu (Can not be larger than 49)
    billCommandName = "bill",                 -- Command to open the bill menu
    adminMenuCommandName = "manageSocieties", -- Command to open the admin menu
    bill_receiptitem = "bcc_society_receipt",
    blips = {                                 --Blips you can choose when making societies (You can add as many as you want just follow the layout)
        {
            blipName = "Gun Store",
            blipHash = "blip_shop_gunsmith"
        },
        {
            blipName = "Clothing Store",
            blipHash = 'blip_shop_tailor'
        },
        {
            blipName = "General Store",
            blipHash = 'blip_shop_store'
        },
        {
            blipName = "Barber Shop",
            blipHash = 'blip_shop_barber'
        },
        {
            blipName = "Blacksmith",
            blipHash = 'blip_shop_blacksmith'
        },
        {
            blipName = "Doctor Office",
            blipHash = 'blip_shop_doctor'
        },
        {
            blipName = "Stables",
            blipHash = 'blip_shop_horse'
        },
        {
            blipName = "Saloon",
            blipHash = 'blip_saloon'
        }
    }
}
