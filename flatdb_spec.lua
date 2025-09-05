-- Test suite for the refactored FlatDB module.
-- To run: busted flatdb_spec.lua

describe("FlatDB", function()
    local flatdb = require("flatdb")
    local TEST_DIR = "./test_db"

    -- Setup: Create a clean test directory before each test.
    before_each(function()
        -- Clean up any previous test directory
        os.execute("rm -rf " .. TEST_DIR)
        os.execute("mkdir " .. TEST_DIR)
    end)

    -- Teardown: Remove the test directory after each test.
    after_each(function()
        os.execute("rm -rf " .. TEST_DIR)
    end)

    it("should create a database object for a valid directory", function()
        local db = flatdb(TEST_DIR)
        assert.is_not_nil(db)
        assert.are.equal("table", type(db))
    end)

    it("should assert if the directory does not exist", function()
        local non_existent_dir = "./non_existent_db"
        assert.has_error(function()
            flatdb(non_existent_dir)
        end, "'" .. non_existent_dir .. "' is not a valid directory.")
    end)

    it("should create a new page and store data in memory", function()
        local db = flatdb(TEST_DIR)
        db.users = {
            { name = "Alice", id = 1 },
            { name = "Bob", id = 2 }
        }
        assert.are.equal(2, #db.users)
        assert.are.equal("Alice", db.users[1].name)
    end)

    it("should return nil for a non-existent page", function()
        local db = flatdb(TEST_DIR)
        assert.is_nil(db.products)
    end)

    it("should save a specific page to a file", function()
        local db = flatdb(TEST_DIR)
        local page_path = TEST_DIR .. "/settings"

        db.settings = { theme = "dark", language = "en" }
        local success = db:save("settings")

        assert.is_true(success)

        -- Verify file content
        local f = io.open(page_path, "r")
        assert.is_not_nil(f, "File was not created.")
        local content = f:read("*a")
        f:close()

        -- A simple check to see if the content seems correct
        assert.matches('"theme":"dark"', content)
        assert.matches('"language":"en"', content)
    end)

    it("should lazy-load a page from a file", function()
        local page_path = TEST_DIR .. "/inventory"
        local file_content = '{"item":"sword","quantity":10,"tags":["weapon","melee"]}'

        -- Manually create a file to simulate a pre-existing page
        local f = io.open(page_path, "w")
        f:write(file_content)
        f:close()

        -- Create a new db instance to ensure data is not already in memory
        local db = flatdb(TEST_DIR)

        -- Accessing `db.inventory` should trigger a load from the file
        local inventory_page = db.inventory
        assert.is_not_nil(inventory_page)
        assert.are.equal("sword", inventory_page.item)
        assert.are.equal(10, inventory_page.quantity)
        assert.are.equal("weapon", inventory_page.tags[1])
    end)

    it("should save all pages", function()
        local db = flatdb(TEST_DIR)
        db.users = { { name = "Charlie" } }
        db.config = { version = "1.0" }

        local success = db:save()
        assert.is_true(success)

        -- Verify both files exist
        local user_file = io.open(TEST_DIR .. "/users", "r")
        local config_file = io.open(TEST_DIR .. "/config", "r")

        assert.is_not_nil(user_file)
        assert.is_not_nil(config_file)

        user_file:close()
        config_file:close()
    end)
    
    it("should retrieve data correctly after saving and reloading", function()
        -- First session
        local db1 = flatdb(TEST_DIR)
        db1.game_state = { level = 5, score = 1250 }
        db1:save("game_state")

        -- Second session (new instance)
        local db2 = flatdb(TEST_DIR)
        assert.is_not_nil(db2.game_state)
        assert.are.equal(5, db2.game_state.level)
        assert.are.equal(1250, db2.game_state.score)
    end)

    it("should allow extending methods via the hack table", function()
        flatdb.hack.clear_page = function(db, page_name)
            if db[page_name] then
                db[page_name] = {}
                return true
            end
            return false
        end
        
        local db = flatdb(TEST_DIR)
        db.logs = { "entry1", "entry2" }
        assert.are.equal(2, #db.logs)
        
        local success = db:clear_page("logs")
        assert.is_true(success)
        assert.are.equal(0, #db.logs)
    end)
end)
