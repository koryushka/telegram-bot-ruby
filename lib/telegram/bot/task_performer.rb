module Telegram
  module Bot
    class TaskPerformer

      def initialize(task:, interval: 3600)
        @task = task
        @interval = interval
      end

      def call
        return unless task
        return invoke unless last_invocation
        return if Time.current - last_invocation <= interval
        p "Performing the task: #{Time.current}"

        invoke
      end

      private

      attr_reader :task, :interval, :last_invocation

      def invoke
        task.call 
        @last_invocation = Time.current
      end
    end
  end
end
