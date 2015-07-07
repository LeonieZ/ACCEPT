classdef (ConstructOnLoad) logmessage < event.EventData
    %LOGMESSAGE is a custom event class that is used to pass messages to the logger class. 

    
    properties
        message  %The log message, this ahs to be a string. 
        logLevel %1..4 future proofing so we can decide on the amount of logging. 
    end
    
    methods
        function self=logmessage(level,message)
        validateattributes(level,{'numeric'},{'integer','>=',1,'<=',4},'','level');
        validateattributes(message,{'char'},{'nonempty'},'','message');
        self.message=message;
        self.logLevel=level;
        end
    end
    
end

