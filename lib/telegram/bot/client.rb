module Telegram
  module Bot
    class Client
      attr_reader :api, :options
      attr_accessor :logger

      def self.run(*args, &block)
        new(*args).run(&block)
      end

      def initialize(token, hash = {})
        @options = default_options.merge(hash)
        @api = Api.new(token, url: options.delete(:url))
        @logger = options.delete(:logger)
      end

      def run
        yield self
      end

      def listen(&block)
        logger.info('Starting bot')
        running = true
        Signal.trap('INT') { running = false }
        while running
          perform_task(task: options[:task], interval: options[:interval]) if options[:task]
          fetch_updates(&block)
        end
        exit
      end

      def perform_task(task: nil, interval: nil)
        last_invocation = instance_variable_get(:@last_invocation)
        return set_last_invocation unless last_invocation
        return if Time.current - last_invocation <= interval

        task.call 
        set_last_invocation
      end

      def set_last_invocation
        instance_variable_set(:@last_invocation, Time.current)
      end

      def fetch_updates
        response = api.getUpdates(options)
        return unless response['ok']

        response['result'].each do |data|
          yield handle_update(Types::Update.new(data))
        end
      rescue Faraday::TimeoutError
        retry
      end

      def handle_update(update)
        @options[:offset] = update.update_id.next
        message = update.current_message
        log_incoming_message(message)

        message
      end

      private

      def default_options
        {
          offset: 0,
          timeout: 20,
          logger: NullLogger.new,
          url: 'https://api.telegram.org'
        }
      end

      def log_incoming_message(message)
        uid = message.respond_to?(:from) && message.from ? message.from.id : nil
        logger.info(
          format('Incoming message: text="%s" uid=%s', message, uid)
        )
      end
    end
  end
end
