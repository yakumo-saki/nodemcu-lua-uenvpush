-- Logger class
-- files: 
-- log-lastused.log  -> last used log no.
-- log-{lognum}.log  -> log file

Logger = {}
Logger.LAST_USED_FILE = "log-lastused.log"
Logger.FILE_PREFIX = "log-"
Logger.FILE_SUFFIX = ".log"
Logger.LOG_FILE_NO = 0
Logger.MAX_LOG_FILES = 9

Logger.create = function()
    pattern = Logger.FILE_PREFIX .. "%%d" .. Logger.FILE_SUFFIX
    l = file.list();
    for k,v in pairs(l) do
    print("name:" .. k ..", size:" .. v)
    end

    local obj = {}
    obj.LOG_FILENAME = Logger.get_filename()
    obj.EXTRA_FUNC = nil

    obj.init = function(self)
        print(self.LOG_FILENAME)
        -- self.LOG_FILE = file.open(self.LOG_FILENAME, "w")
        -- if self.LOG_FILE == nil then
            -- print(self.LOG_FILENAME .. " open failed (flag w)")
        -- end
    end
    
    obj.close = function(self)
        self.info("Log file closed.")
        -- do nothing.
    end

    obj.add_extra_handler = function(self, func)
        self.EXTRA_FUNC = func
    end

    obj.debug = function(self, msg)
        self.log(self, "DEBUG", msg)
    end

    obj.info = function(self, msg)
        self.log(self, "INFO", msg)
    end

    obj.warn = function(self, msg)
        self.log(self, "WARN", msg)
    end

    obj.error = function(self, msg)
        self.log(self, "ERROR", msg)
    end

    obj.log = function(self, level, msg)
        local log = string.format("%s %s %s", tmr.now(), level, msg)
        print(log)

        -- log file open / close per line. because open once and appending causes exception.
        logfile = file.open(self.LOG_FILENAME, "a")
        logfile.writeline(log)
        logfile.close()

        if (self.EXTRA_FUNC ~= nil) then
            self.EXTRA_FUNC(msg)
        end
    end

    obj:init()
    return obj
end

Logger.get_filename = function()
    local file_no = 0
    if file.exists(Logger.LAST_USED_FILE) then
        print("lastused file found")

        if file.open(Logger.LAST_USED_FILE, "r") then
            file_line = file.readline()
            file_no = tonumber(file_line)
            file.close()
        end
    else
        print("lastused file not found. using index 0")
        file_no = -1
    end

    -- decide filename
    file_no = file_no + 1
    if (file_no > Logger.MAX_LOG_FILES) then
        print("index rollover. file_no = 0")
        file_no = 0
    end 

    NOW_FILE = Logger.FILE_PREFIX .. string.format("%i", file_no) .. Logger.FILE_SUFFIX
    print ("NOW_FILE = " .. NOW_FILE)

    if file.open(Logger.LAST_USED_FILE, "w") then
        file.write(file_no)
        file.close()
        print("log index updated => " .. file_no)
    else   
        print("log index file update failed!")
    end

    return NOW_FILE
end

