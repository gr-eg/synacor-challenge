require 'byebug'

class VM
  OPERATIONS = {
    0 => :halt,
    19 => :out,
    21 => :noop,
    6 => :jmp,
    7 => :jt,
    8 => :jf
  }.freeze

  def initialize(machine)
    @machine = machine
    @instructions = File.read(@machine).unpack('v*')
    @registers = []
    @index = 0
    @next_instruction = nil
  end

  def run
    execute(@instructions)
  end

  def execute(instructions)
    @index = 0
    while @index < instructions.count
      @next_instruction = nil
      send(OPERATIONS[instructions[@index]] || :not_implemented)
      @index = @next_instruction || @index += 1
    end
  end

  def out
    print next_instruction.chr
  end

  def jmp
    @next_instruction = next_instruction
  end

  def jt
    ni = next_instruction
    @next_instruction = if ni.zero?
                          @index + 2
                        else
                          next_instruction
                        end
  end

  def jf
    @next_instruction = if next_instruction.zero?
                          next_instruction
                        else
                          @index + 2
                        end
  end

  def noop
  end

  def halt
    exit
  end

  def not_implemented
    puts "NOT_IMPLEMENTED"
  end

  private

  def next_instruction
    @index += 1
    @instructions[@index]
  end
end

VM.new('challenge.bin').run
