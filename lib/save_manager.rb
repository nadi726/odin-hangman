# frozen_string_literal: true

require 'json'
require_relative 'input'

# Save games and load saved games
module SaveManager
  SAVE_FILE_PATH = 'saved_games.json'

  # A bit excessive... Used to verify that the game object is valid
  EXPECTED_KEYS = {
    answer: ->(value, _) { value.is_a?(String) && value.match?(/[a-zA-Z]/) },
    guess_so_far: ->(value, hash) { guess_so_far_valid?(value, hash) },
    guessed_letters: ->(value, _) { value.is_a?(Array) },
    turn: ->(value, _) { value.is_a?(Integer) && value >= 0 }
  }.freeze

  # convert game state to json
  def self.game_as_json(game)
    attributes = %i[answer guess_so_far guessed_letters turn]
    attributes.to_h { |attr| [attr, game.send(attr)] }
  end

  # add the game data to the save file
  def self.save_game(game)
    puts 'Saving game...'
    File.open(SAVE_FILE_PATH, 'r+') do |file|
      contents = load_valid_games file.read
      file.rewind
      contents.push game_as_json(game)
      file.write JSON.pretty_generate(contents)
    end
    puts 'Done.'
  end

  # return an array of valid game states from the save file
  def self.load_valid_games(str)
    begin
      contents = JSON.parse(str, symbolize_names: true)
    rescue JSON::ParserError
      contents = []
    end
    contents.is_a?(Array) ? filter_valid_data(contents) : []
  end

  # load the save file and prompt the user to choose a saved game, if there are any
  def self.load_game
    games = load_valid_games(File.read(SAVE_FILE_PATH))
    return if games.empty?
    return unless load_saved_game?

    choose_game games
  end

  # Only include saved games with valid states
  def self.filter_valid_data(contents)
    contents.select do |game|
      EXPECTED_KEYS.all? do |key, lambda|
        game.include?(key) && lambda.call(game[key], game)
      end
    end
  end

  # A helper method for EXPECTED_KEYS
  def self.guess_so_far_valid?(guess, hash)
    answer = hash[:answer]
    guess.is_a?(Array) && guess.length == answer.length &&
      guess.each_index.all? { |i| guess[i] == '-' || guess[i] == answer[i] }
  end

  def self.load_saved_game?
    response = Input.get('Do you want to load a saved game(y/N)? ')
    true if response.downcase == 'y'
  end

  # determine the game the user wants to load out of all saved games
  def self.choose_game(games)
    return games[0] if games.length == 1

    loop do
      response = determine_game_choice(games.length - 1)
      return games[response] if response
    end
  end

  # Return a choice for a valid game entry in the games array, or nil
  def self.determine_game_choice(max_choice)
    response = Input.get "Choose a game to load[0-#{max_choice}]: "

    begin
      response = Integer response
    rescue ArgumentError
      puts 'Please enter a valid number.'
      return
    end

    return response if response.between?(0, max_choice)

    puts 'Please enter an integer in range.'
  end
end
