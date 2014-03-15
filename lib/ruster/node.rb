class Ruster::Node
  include Ruster::Util

  attr :addr
  attr :id
  attr :flags
  attr :master_id
  attr :ping_epoch
  attr :pong_epoch
  attr :config_epoch
  attr :state
  attr :slots
  attr :migrating
  attr :importing
  attr :friends

  def initialize(addr)
    @addr = addr
  end

  def client
    @client ||= Redic.new("redis://#{addr}")
  end

  def call(*args)
    res = client.call(*args)
    raise res if res.is_a?(RuntimeError)
    res
  end

  def enabled?
    parse_info(call("INFO", "cluster"))[:cluster_enabled] == "1"
  end

  def read_info_line!(info_line)
    parts = info_line.split

    @id = parts.shift
    addr = parts.shift
    @flags = parts.shift.split(",")
    @addr = addr unless @flags.include?("myself")
    @master_id = parts.shift
    @ping_epoch = parts.shift.to_i
    @pong_epoch = parts.shift.to_i
    @config_epoch = parts.shift.to_i
    @state = parts.shift
    @slots = []
    @migrating = {}
    @importing = {}

    parts.map do |slots|
      case slots
      when /^(\d+)-(\d+)$/ then @slots << ($1.to_i..$2.to_i)
      when /^\d+$/ then @slots << (slots.to_i..slots.to_i)
      when /^\[(\d+)-([<>])-([a-z0-9]+)\]$/
        case $2
        when ">" then @migrating[$1.to_i] = $3
        when "<" then @importing[$1.to_i] = $3
        end
      end
    end.compact
  end

  def all_slots
    slots.map(&:to_a).flatten
  end

  def to_s
    "#{addr} [#{id}]"
  end

  def self.from_info_line(info_line)
    _, addr, _ = info_line.split
    new(addr).tap { |node| node.read_info_line!(info_line) }
  end

  def load!
    @friends = []

    call("CLUSTER", "NODES").split("\n").each do |line|
      if line.include?("myself")
        read_info_line!(line)
      else
        @friends << self.class.from_info_line(line)
      end
    end
  end

  def meet(ip, port)
    call("CLUSTER", "MEET", ip, port)
  end

  def forget(node)
    call("CLUSTER", "FORGET", node.id)
  end
end
