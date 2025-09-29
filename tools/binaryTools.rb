# Converts a binary string to its hexadecimal representation.
#
# @param binary_str [String] The binary string to convert. May contain whitespace.
# @return [String] The hexadecimal representation of the binary string, in uppercase.
# @raise [ArgumentError] If the input contains characters other than '0' or '1'.
#
# @example
#   binary_to_hex("1010")      # => "A"
#   binary_to_hex("  1101  ")  # => "D"
#   binary_to_hex("1001 0110") # => "96"
def binary_to_hex(binary_str)
  # Remove any whitespace and validate input
  clean_str = binary_str.strip.gsub(/\s+/, '')
  unless clean_str.match?(/\A[01]+\z/)
    raise ArgumentError, "Input must be a string containing only 0 and 1"
  end

  # Pad the string to a multiple of 4 bits for hex conversion
  padded_str = clean_str.rjust((clean_str.length + 3) & ~3, '0')

  # Convert binary string to integer, then to hex
  hex_str = padded_str.to_i(2).to_s(16).upcase

  hex_str
end