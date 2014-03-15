module Ruster::Util
  def parse_info(info)
    {}.tap do |data|
      info.split.each do |line|
        key, val = line.split(":")
        data[key.to_sym] = val
      end
    end
  end
end
