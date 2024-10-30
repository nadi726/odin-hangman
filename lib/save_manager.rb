# frozen_string_literal: true

require 'json'

# Save games and load saved games
module SaveManager
  SAVE_FILE_PATH = 'saved_games.json'

  def self.as_json(game)
    {
      answer: game.answer,
      guess_so_far: game.guess_so_far,
      guessed_letters: game.guessed_letters,
      turn: game.turn - 1
    }
  end

  def self.save_game(game)
    puts 'Saving game...'
    File.open(SAVE_FILE_PATH, 'r+') do |file|
      contents = load_json file.read
      file.rewind
      contents.push as_json(game)
      file.write JSON.pretty_generate(contents)
    end
  end

  def self.load_json(str)
    begin
      contents = JSON.parse str
    rescue JSON::ParserError
      contents = []
    end
    contents.is_a?(Array) ? contents : []
  end

  # load the save file and prompt the user to choose a save file, if there are any
  def self.load_game
    puts 'hiya'
  end
end
