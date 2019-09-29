module MessageStore
  module Get
    class Substitute
      include Initializer
      include Virtual

      include Get

##      initializer :stream_name, na(:batch_size), :condition

## Should not be needed
      # def stream_name
      #   @stream_name ||= 'someStream-123'
      # end

      attr_accessor :stream_name

      def batch_size
        @batch_size ||= 1
      end
      attr_writer :batch_size

      def items
        @items ||= []
      end

## How can this be built?
## Substitute requires parameterless build
## How does stream name get in-play when using substitute?
      # def self.build(stream_name, batch_size: nil, session: nil, condition: nil)
      #   new(stream_name, batch_size, condition)
      # end

      def self.build
        new
      end

      # def call(position: nil)
      def call(position)
        position ||= 0

        logger.trace(tag: :get) { "Getting (Position: #{position}, Batch Size: #{batch_size}, Stream Name: #{stream_name.inspect})" }

        logger.debug(tag: :data) { "Items: \n#{items.pretty_inspect}" }
        logger.debug(tag: :data) { "Position: #{position.inspect}" }
        logger.debug(tag: :data) { "Batch Size: #{batch_size.inspect}" }

## Specialized get will replace this with polymorphism
##        unless self.class.category?(stream_name)
        unless self.class.category_stream?(stream_name)
          index = (items.index { |i| i.position >= position })
        else
          index = (items.index { |i| i.global_position >= position })
        end

        logger.debug(tag: :data) { "Index: #{index.inspect}" }

        if index.nil?
          items = []
        else
          range = index..(index + batch_size - 1)
          logger.debug(tag: :data) { "Range: #{range.pretty_inspect}" }

          items = self.items[range]
        end

        logger.info(tag: :data) { "Got: \n#{items.pretty_inspect}" }
        logger.info(tag: :get) { "Finished getting (Position: #{position}, Stream Name: #{stream_name.inspect})" }

        items
      end

      def self.category_stream?(stream_name)
        StreamName.category?(stream_name)
      end
    end
  end
end
