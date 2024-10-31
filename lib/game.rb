# frozen_string_literal: true

require_relative 'input'
require_relative 'save_manager'

# Main game class
class Game
  attr_accessor :turn, :answer, :guess_so_far, :guessed_letters

  TURNS = 10
  WORDS_FILE_PATH = 'google-10000-english-no-swears.txt'
  WORD_LENGTH_RANGE = (5..12).freeze

  def initialize
    loaded_game = SaveManager.load_game
    if loaded_game
      make_game_from_hash loaded_game
      puts "loaded game.\n\n"
    else
      make_new_game
    end
    @game_status = :ongoing # game_status is one of: :ongoing, :win, :lose, :saved
  end

  # setup the game state given a hash
  def make_game_from_hash(hash)
    attributes = %i[turn answer guess_so_far guessed_letters]
    attributes.each do |attribute|
      instance_variable_set("@#{attribute}", hash[attribute])
    end
  end

  # setup a new game state
  def make_new_game
    puts "Making a new game.\n\n"
    @turn = 0
    @answer = make_answer
    @guess_so_far = Array.new(@answer.length, '-')
    @guessed_letters = []
  end

  # Main method. Run it to play the current game
  def play
    print "Game starts\n\n"
    play_turn while @game_status == :ongoing
    post_game
  end

  # Play one turn in the game
  def play_turn
    @turn += 1
    puts "Turn #{@turn}/#{TURNS}\nYour guess so far: #{@guess_so_far.join}"
    update_guessed read_input
    check_game_status
    puts
  end

  # Perform post-game operations, based on the game status
  def post_game
    if @game_status == :win || @game_status == :lose
      puts "The answer was: #{@answer}"
      puts @game_status == :win ? 'You win' : 'You lost'
    elsif @game_status == :saved
      SaveManager.save_game self
    end
  end

  # load the word file and choose a valid word
  def make_answer
    File.open WORDS_FILE_PATH do |file|
      words = file.readlines.filter_map do |w|
        w = w.strip
        w if WORD_LENGTH_RANGE.member? w.length
      end
      words.sample
    end
  end

  # Prompt the user for input until a valid input is given(either a letter or 'save')
  def read_input
    loop do
      user_input = (Input.get 'Guess a letter: ').downcase
      return if user_input == 'save'

      validation_message = get_validation_message user_input
      return user_input if validation_message.nil?

      puts validation_message
    end
  end

  def get_validation_message(guess)
    if !(guess.size == 1 && guess.match?(/[a-zA-Z]/))
      'Please choose a valid letter'
    elsif @guessed_letters.include? guess
      'You have already guessed this letter.'
    end
  end

  # Update to include the current guess
  def update_guessed(guess)
    if guess.nil?
      @game_status = :saved
      @turn -= 1 # Saving shouldn't take a turn
      return
    end

    @guessed_letters.append guess
    @answer.chars.each_with_index do |c, i|
      @guess_so_far[i] = guess if c == guess
    end
  end

  # Update the game status if neccesary
  def check_game_status
    return if @game_status != :ongoing

    if !@guess_so_far.include? '-'
      @game_status = :win
    elsif @turn >= TURNS
      @game_status = :lose
    end
  end
end
