module I18nTemplate
  ## 
  # Document processing node
  class Node
    # The array of children of this node. Not all nodes have children.
    attr_reader :children

    # The parent node of this node. All nodes have a parent, except for the
    # root node.
    attr_reader :parent

    # The line number of the input where this node was begun
    attr_reader :line

    # The byte position in the input where this node was begun
    attr_reader :position

    # Node token
    attr_reader :token

    attr_accessor :tag
    attr_accessor :phrase

    # Create a new node as a child of the given parent.
    def initialize(parent, line = 0, position = 0, token = nil, tag = nil, &block)
      @parent = parent
      @children = []
      @line, @position = line, position
      @token = token
      @tag = tag
      instance_eval(&block) if block_given?
    end

    # tag node?
    def tag?
      !@tag.nil?
    end

    # text node?
    def text?
      @tag.nil?
    end

    # root node?
    def root?
      parent == self
    end

    # Return descendant text if tag node is wrapper node for some text node
    # @return 'text' for
    # <div><span><b>text</b></span><div>
    # @return nil for
    # <div><span><b>text</b></span><p>data</p><div>
    def wrapped_node_text
      node = self
      while node.children.size == 1
        node = node.children.first
        return node.token if node.text?
      end
      return nil
    end

    def descendants_text
      output = ""
      children.each do |child|
        output << child.token if child.text?
        child.children.each do |node|
          output << node.descendants_text
        end
      end
      output
    end
  end
end
