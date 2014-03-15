module Ruster::Util
  def parse_info(info)
    {}.tap do |data|
      info.split("\r\n").each do |line|
        next if line[0] == "#"
        key, val = line.split(":")
        data[key.to_sym] = val
      end
    end
  end
end
