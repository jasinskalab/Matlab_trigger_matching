classdef treeNode
    %TREENODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Data that will be carried by the node. Since matlab has no typing
        %this can be anything and can be different for each node (not
        %recommended)
        data
        
        %"pointers" to the child and parent nodes.
        leftNode
        rightNode
        centerNode
        parentNode
    end
    
    methods
        function obj = treeNode(parentNode,leftNode,rightNode,centerNode)
            %TREENODE Construct an instance of this class
            %   This is the most basic instance of our class
            %   Matlab does not allow multiple functions of the same name
            %   but allows instead for a variable number of inputs whenever
            %   the function is called. A node always needs a parent node
            %   unless it is the root
            if(nargin>3)
                obj.leftNode = leftNode;
            elseif(nargin>2)
                obj.rightNode = rightNode;
            elseif(nargin>1)
                obj.centerNode = centerNode;
            elseif(nargin>0)
                obj.parentNode = parentNode;
            end
            
            
            
        end
        
        
    end
end

