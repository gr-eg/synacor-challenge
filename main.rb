require 'byebug'

class VM
  OPERATIONS = {
    0 => :halt,
    1 => :set,
    2 => :push,
    3 => :pop,
    4 => :eq,
    5 => :gt,
    6 => :jmp,
    7 => :jt,
    8 => :jf,
    9 => :add,
    12 => :and,
    13 => :or,
    14 => :not,
    17 => :call,
    19 => :out,
    21 => :noop
  }.freeze

  def initialize(machine)
    @machine = machine
    @instructions = File.read(@machine).unpack('v*')
    @registers = []
    @stack = []
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

  def set
    register, value = register_and_value
    @registers[register] = value
  end

  def add
    register, v1, v2 = register_and_two_values
    value = (v1 + v2) % 32_768
    @registers[register] = value
  end

  def eq
    register, v1, v2 = register_and_two_values
    value = v1 == v2 ? 1 : 0
    @registers[register] = value
  end

  def push
    @stack.push(next_instruction)
  end

  def pop
    @registers[register] = @stack.pop
  end

  def gt
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 > v2 ? 1 : 0
  end

  def and
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 & v2
  end

  def or
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 | v2
  end

  def not
    register, value = register_and_value
    @registers[register] = (~ value) & 32_767
  end

  def call
    @stack.push @index
    jump_point = next_instruction
    @next_instruction = jump_point
  end

  def noop
  end

  def halt
    exit
  end

  def not_implemented
    puts "NOT_IMPLEMENTED: #{@instructions[@index]}"
  end

  private

  def next_instruction
    @index += 1
    ni = @instructions[@index]
    if ni >= 32_768
      ni = get_register(ni)
    end
    ni
  end

  def register
    @index += 1
    register_index = 32_775 - @instructions[@index]
    register_index
  end

  def register_and_value
    [register, next_instruction]
  end

  def register_and_two_values
    [*register_and_value, next_instruction]
  end

  def get_register(register)
    @registers[(32_775 - register)] || 0
  end
end

VM.new('challenge.bin').run
