class Counter
  attr_reader :total

  def initialize
    puts 'initialized'
    @total = 0
    @mutex = Mutex.new
  end

  def increment!
    @mutex.synchronize { @total += 1 }
  end
end