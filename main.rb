require 'byebug'
require 'io/console'

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
    10 => :mult,
    11 => :mod,
    12 => :and,
    13 => :or,
    14 => :not,
    15 => :rmem,
    16 => :wmem,
    17 => :call,
    18 => :ret,
    19 => :out,
    20 => :in,
    21 => :noop
  }.freeze

  def initialize(machine)
    @machine = machine
    @instructions = File.read(@machine).unpack('v*')
    @registers = []
    @stack = []
    @next_instruction = nil
    @input = []
  end

  def run
    execute(@instructions)
  end

  def execute(instructions)
    @index = 1
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

  def mult
    register, v1, v2 = register_and_two_values
    @registers[register] = (v1 * v2) % 32_768
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

  def mod
    register, v1, v2 = register_and_two_values
    @registers[register] = (v1 % v2)
  end

  def or
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 | v2
  end

  def not
    register, value = register_and_value
    @registers[register] = (~ value) & 32_767
  end

  def rmem
    register, value = register_and_value
    @registers[register] = @instructions[value]
  end

  def wmem
    register, value = two_instructions
    @instructions[register] = value
  end

  def call
    @stack.push @index + 2
    jump_point = next_instruction
    @next_instruction = jump_point
  end

  def ret
    @next_instruction = @stack.pop
  end

  def in
    char = @input.any? ? @input.shift : $stdin.getc
    if char == "~"
      File.read("maze.txt").chomp.each_char { |x| @input << x }
      char = @input.shift
    end
    if char == "*"
      byebug
      @registers[0] = 25976
      @input = "use teleporter".split ""
      char = @input.shift
    end
    reg = register
    puts "Saving #{char} to #{reg}"
    @registers[reg] = char.ord
  end

  def noop
  end

  def halt
    exit
  end

  def not_implemented
  end

  private

  def next_instruction
    @index += 1
    ni = @instructions[@index]
    ni < 32_768 ? ni : get_register(ni)
  end

  def two_instructions
    [next_instruction, next_instruction]
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
