module I18nTemplate
  ##
  # Handler is ActionView wrapper for erb handler.
  # If internationalize? returns true
  # it calls erb handler with internationalized template
  # otherwise it calls handler with regular template
  class Handler
    def initialize(options = {})
      @options = options
      @default_format = ::Mime::HTML
      init_erb_handler
    end

    # default format
    attr_reader :default_format

    # erb handler
    attr_reader :erb_handler

    # call method implements ActionView::Template handler interface
    def call(template)
      if internationalize?(template)
        document = ::I18nTemplate::Document.new(template.source)
        document.process!
        document.warnings.each { |warning| $stderr.puts warning } if @options[:verbose]

        erb_handler.call(document)
      else
        erb_handler.call(template)
      end
    end

    protected

    # check if template source should be internationalized
    #
    # @note 
    #   if you need more control inherite and override this method
    def internationalize?(template)
      true
    end

    private

    # init action_view erb handler
    def init_erb_handler
      require 'action_pack/version'

      case ActionPack::VERSION::MAJOR
      when 2
        require 'action_view/template_handlers/erb'
        @erb_handler = ::ActionView::TemplateHandlers::ERB
      when 3
        require 'action_view/template/handlers/erb'
        @erb_handler = ::ActionView::Template::Handlers::ERB
      else
        raise NotImplementedError, "Can't init erb_handler for action_pack v#{ActionPack::VERSION::STRING}"
      end
    end
  end
end
