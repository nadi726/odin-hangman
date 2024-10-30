# frozen_string_literal: true

require_relative 'input'
require_relative 'save_manager'

# Main game class
class Game
  attr_reader :turn, :answer, :guess_so_far, :guessed_letters

  TURNS = 7
  WORDS_FILE_PATH = 'google-10000-english-no-swears.txt'
  WORD_LENGTH_RANGE = (5..12).freeze

  def initialize
    @turn = 0
    @answer = make_answer
    @guess_so_far = Array.new(@answer.length, '-')
    @guessed_letters = []
    @game_status = :ongoing # game_status is one of: :ongoing, :win, :lose, :saved
  end

  def play
    print "Game starts\n\n"
    play_turn while @game_status == :ongoing
    post_game
  end

  def play_turn
    @turn += 1
    puts "Turn #{@turn}\nYour guess so far: #{@guess_so_far.join}"
    update_guessed guess_letter
    check_game_status
    puts
  end

  def post_game
    if @game_status == :win || @game_status == :lose
      puts "The asnwer was: #{@answer}"
      if @game_status == :win
        puts 'you win'
      elsif @game_status == :lose
        puts 'You lost'
      end
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

  def guess_letter
    loop do
      guess = (Input.get 'Guess a letter: ').downcase
      return if guess == 'save'

      validation_message = get_validation_message guess
      return guess if validation_message.nil?

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

  def update_guessed(guess)
    if guess.nil?
      @game_status = :saved
      return
    end

    @guessed_letters.append guess
    @answer.chars.each_with_index do |c, i|
      @guess_so_far[i] = guess if c == guess
    end
  end

  def check_game_status
    return if @game_status != :ongoing

    if !@guess_so_far.include? '-'
      @game_status = :win
    elsif @turn >= TURNS
      @game_status = :lose
    end
  end
end
