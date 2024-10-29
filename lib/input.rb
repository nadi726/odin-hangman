# frozen_string_literal: true

# Helper module for the input function
module Input
  # Input with a text directly before, on the same line
  def self.get(text)
    print text
    $stdout.flush
    gets.chomp
  end
end
