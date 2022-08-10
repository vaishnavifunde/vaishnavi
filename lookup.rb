def get_command_line_argument
  if ARGV.empty?
    puts "Usage: ruby lookup.rb <domain>"
    exit
  end
  ARGV.first
end
domain = get_command_line_argument

dns_raw = File.readlines("zone")

def parse_dns(raw)
  raw = raw.map(&:strip)
  raw = raw.reject { |line| line.empty? }
  raw = raw.reject { |line| line.start_with?("#") }
  recordlines = raw.map { |line| line.strip.split(", ") }
  recordlines = recordlines.reject { |record| record.length != 3 }

  dns_records = recordlines.each_with_object({}) do |record, records| records[record[1]] =
    { type: record.first, target: record.last }   end
  dns_records
end

def resolve(dns_records, lookup_chain, domain)
  matched_dns = dns_records[domain]

  if (!matched_dns)
    lookup_chain << "Error: Record not found for " + domain
    return lookup_chain
  end

  if (matched_dns[:type] == "A")
    lookup_chain << matched_dns[:target]
    return lookup_chain
  end

  if (matched_dns[:type] == "CNAME")
    lookup_chain << matched_dns[:target]
    resolve(dns_records, lookup_chain, matched_dns[:target])
    return lookup_chain
  end

  lookup_chain << "Invalid record type for " + domain
  return lookup_chain
end

dns_records = parse_dns(dns_raw)
lookup_chain = [domain]
lookup_chain = resolve(dns_records, lookup_chain, domain)
puts lookup_chain.join(" => ")