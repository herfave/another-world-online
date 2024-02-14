local task = {}

local SUCCESS,FAIL,RUNNING = 1,2,3

-- Any arguments passed into Tree:run(obj) can be received after the first parameter, obj
-- Example: Tree:run(obj,deltaTime) - > task.start(obj, deltaTime), task.run(obj, deltaTime), task.finish(obj, status, deltaTime)

-- Blackboards
    -- objects attached to the tree have tables injected into them called Blackboards.
    -- these can be read from and written to by the tree using the Blackboard node, and can be accessed in tasks via object.Blackboard
--

function task.start(obj)
    --[[
        (optional) this function is called directly before the run method
        is called. It allows you to setup things before starting to run
        Beware: if task is resumed after calling running(), start is not called.
    --]]
    
    local Blackboard = obj.Blackboard
    
end
function task.finish(obj, status)
    --[[
        (optional) this function is called directly after the run method
        is completed with either success() or fail(). It allows you to clean up
        things, after you run the task.
    --]]
    
    local Blackboard = obj.Blackboard 
    
end	
function task.run(obj)
    if obj._waitTime > 0 then
        obj._waitTime -= obj._deltaTime
        return RUNNING
    end
    
    return SUCCESS
end
return task
