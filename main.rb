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
    @debug = ARGV[0] == "true"
    @machine = machine
    @instructions = File.read(@machine).unpack('v*')
    @registers = []
    @stack = []
    @next_instruction = nil
    @log = []
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
    @log << "OUT - #{@index}"
    print next_instruction.chr
  end

  def jmp
    @log << "JMP - #{@index}"
    @next_instruction = next_instruction
  end

  def jt
    @log << "JT - #{@index}"
    ni = next_instruction
    @next_instruction = if ni.zero?
                          @index + 2
                        else
                          next_instruction
                        end
  end

  def jf
    @log << "JF - #{@index}"
    @next_instruction = if next_instruction.zero?
                          next_instruction
                        else
                          @index + 2
                        end
  end

  def set
    @log << "SET - #{@index}"
    register, value = register_and_value
    @registers[register] = value
  end

  def add
    @log << "ADD - #{@index}"
    register, v1, v2 = register_and_two_values
    value = (v1 + v2) % 32_768
    @registers[register] = value
  end

  def mult
    @log << "MULT - #{@index}"
    register, v1, v2 = register_and_two_values
    @registers[register] = (v1 * v2) % 32_768
  end

  def eq
    @log << "EQ - #{@index}"
    register, v1, v2 = register_and_two_values
    value = v1 == v2 ? 1 : 0
    @registers[register] = value
  end

  def push
    @log << "PUSH - #{@index}"
    @stack.push(next_instruction)
  end

  def pop
    @log << "POP - #{@index}"
    @registers[register] = @stack.pop
  end

  def gt
    @log << "GT - #{@index}"
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 > v2 ? 1 : 0
  end

  def and
    @log << "AND - #{@index}"
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 & v2
  end

  def mod
    @log << "MOD - #{@index}"
    register, v1, v2 = register_and_two_values
    @registers[register] = (v1 % v2)
  end

  def or
    @log << "OR - #{@index}"
    register, v1, v2 = register_and_two_values
    @registers[register] = v1 | v2
  end

  def not
    @log << "NOT - #{@index}"
    register, value = register_and_value
    @registers[register] = (~ value) & 32_767
  end

  def rmem
    @log << "RMEM - #{@index}"
    register, value = register_and_value
    @registers[register] = @instructions[value]
  end

  def wmem
    @log << "WMEM - #{@index}"
    # key, value = two_values
    # @memory[key] = value
    register, value = [next_instruction, next_instruction]
    @instructions[register] = value
  end

  def call
    @log << "CALL - #{@index}"
    @stack.push @index + 2
    jump_point = next_instruction
    @next_instruction = jump_point
  end

  def ret
    @log << "RET - #{@index}"
    @next_instruction = @stack.pop
  end

  def in
    # in: 20 a
    #   read a character from the terminal and write its ascii code to <a>;
    #   it can be assumed that once input starts, it will continue until a newline is encountered;
    #   this means that you can safely read whole lines from the keyboard and trust that they will be fully read
    @log << "IN - #{@index}"

    char = $stdin.getch
    puts char
    @instructions[next_instruction] = char.ord
    # puts line
    # char = STDIN.getc
    # halt unless char
    # code = char.ord
    # instruction = raw_instruction
    # register, value = register_and_value
    # @memory[register] = value
    # if register? instruction
    #   key = register_id instruction
    #   @registers[key] = code
    # else
    #   @memory[instruction] = code
    # end
  end


  def noop
    @log << "NOOP - #{@index}"
  end

  def halt
    @log << "HALT - #{@index}"
    @log.each { |x| puts x } if @debug
    exit
  end

  def not_implemented
    @log << "NOT_IMPLEMENTED - #{@instructions[@index]}"
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
