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

  def replicate(node)
    call("CLUSTER", "REPLICATE", node.id)
  end

  def slaves
    call("CLUSTER", "SLAVES", id).map do |line|
      self.class.from_info_line(line)
    end
  end

  def add_slots(*slots)
    call("CLUSTER", "ADDSLOTS", *slots)
  end

  def del_slots(*slots)
    call("CLUSTER", "DELSLOTS", *slots)
  end

  def flush_slots!
    call("CLUSTER", "FLUSHSLOTS")
  end

  def cluster_info
    parse_info(call("CLUSTER", "INFO"))
  end

  def ip
    addr.split(":").first
  end

  def port
    addr.split(":").last
  end

  # In Redis Cluster only DB 0 is enabled
  DB0 = 0

  def move_slot!(slot, target, options={})
    options[:num_keys] ||= 10
    options[:timeout]  ||= call("CONFIG", "GET", "cluster-node-timeout")

    # Tell the target node to import the slot
    target.call("CLUSTER", "SETSLOT", slot, "IMPORTING", id)

    # Tell the current node to export the slot
    call("CLUSTER", "SETSLOT", slot, "MIGRATING", target.id)

    # Export keys
    done = false
    until done
      keys = call("CLUSTER", "GETKEYSINSLOT", slot, options[:num_keys])

      done = keys.empty?

      keys.each do |key|
        call("MIGRATE", target.ip, target.port, key, DB0, options[:timeout])
      end

      # Tell cluster the location of the new slot
      call("CLUSTER", "SETSLOT", slot, "NODE", target.id)

      friends.each do |node|
        friend.call("CLUSTER", "SETSLOT", slot, "NODE", target.id)
      end
    end
  end

  def empty?
    call("DBSIZE") == 0
  end
end
